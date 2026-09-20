#!/usr/bin/env bash
# Link the launcher, the sync script, the desktop entry and the systemd user
# timer into place. Re-run after pulling changes; everything is symlinked.
set -euo pipefail
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

for tool in icloudpd quickshell magick ffmpeg ffprobe jq wl-copy; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$config/systemd/user" "$config/icloud-recent"
ln -sf "$here/bin/icloud-recent" "$HOME/.local/bin/icloud-recent"
ln -sf "$here/bin/icloud-recent-sync" "$HOME/.local/bin/icloud-recent-sync"
# The desktop entry is copied, not linked, so the icon can get its absolute path.
sed "s|@ICON@|$here/assets/icon.png|" "$here/icloud-recent.desktop" > "$HOME/.local/share/applications/icloud-recent.desktop"
ln -sf "$here/systemd/icloud-recent-sync.service" "$config/systemd/user/icloud-recent-sync.service"
ln -sf "$here/systemd/icloud-recent-sync.timer" "$config/systemd/user/icloud-recent-sync.timer"

if [ ! -f "$config/icloud-recent/config" ]; then
  cat > "$config/icloud-recent/config" <<CFG
# icloud-recent configuration, sourced by icloud-recent-sync
# APPLE_ID is filled in by the sign-in card in the app.
LIBRARY=\$HOME/Pictures/iCloud
DAYS=7
CFG
  echo "Start icloud-recent and sign in with your Apple ID."
fi

# The trash helper talks to iCloud through pyicloud, which comes with the
# icloudpd sources. It lives in a virtualenv inside the repository.
if [ ! -x "$here/.venv/bin/python" ]; then
  py=python3
  for cand in "$HOME"/.local/share/mise/installs/python/3.13*/bin/python3 "$HOME"/.local/share/mise/installs/python/3.12*/bin/python3; do
    [ -x "$cand" ] && { py="$cand"; break; }
  done
  "$py" -m venv "$here/.venv"
  "$here/.venv/bin/pip" install -q "git+https://github.com/icloud-photos-downloader/icloud_photos_downloader@v1.32.3"
fi

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
systemctl --user daemon-reload
systemctl --user enable --now icloud-recent-sync.timer
echo "installed; next sync: $(systemctl --user list-timers icloud-recent-sync.timer --no-pager | sed -n 2p | awk '{print $1, $2, $3}')"
