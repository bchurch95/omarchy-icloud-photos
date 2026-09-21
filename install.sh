#!/usr/bin/env bash
# Link the launcher, the sync script, the desktop entry and the systemd user
# timer into place. Re-run after pulling changes; everything is symlinked.
set -euo pipefail
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

for tool in quickshell magick ffmpeg ffprobe jq wl-copy; do
  command -v "$tool" >/dev/null || { echo "missing: $tool (pacman -S quickshell imagemagick ffmpeg jq wl-clipboard)" >&2; exit 1; }
done

# icloudpd: the AUR package if you have it, otherwise the release binary goes
# into ~/.local/bin so nothing here needs root.
ICLOUDPD_VERSION=1.32.3
if ! command -v icloudpd >/dev/null; then
  case "$(uname -m)" in
    x86_64) arch=amd64 ;;
    aarch64) arch=arm64 ;;
    *) echo "no icloudpd binary for $(uname -m); install the AUR package icloudpd-bin" >&2; exit 1 ;;
  esac
  mkdir -p "$HOME/.local/bin"
  echo "downloading icloudpd $ICLOUDPD_VERSION…"
  curl -fsSL -o "$HOME/.local/bin/icloudpd" \
    "https://github.com/icloud-photos-downloader/icloud_photos_downloader/releases/download/v$ICLOUDPD_VERSION/icloudpd-$ICLOUDPD_VERSION-linux-$arch"
  chmod +x "$HOME/.local/bin/icloudpd"
fi

# Installs from before the rename (everything was called icloud-recent) move
# over: config and cache keep their contents, the old links and units go.
cache="${XDG_CACHE_HOME:-$HOME/.cache}"
if [ -d "$config/icloud-recent" ] && [ ! -d "$config/omarchy-icloud-photos" ]; then
  mv "$config/icloud-recent" "$config/omarchy-icloud-photos"
fi
if [ -d "$cache/icloud-recent" ] && [ ! -d "$cache/omarchy-icloud-photos" ]; then
  mv "$cache/icloud-recent" "$cache/omarchy-icloud-photos"
fi
if [ -e "$config/systemd/user/icloud-recent-sync.timer" ]; then
  systemctl --user disable --now icloud-recent-sync.timer 2>/dev/null || true
  rm -f "$config/systemd/user/icloud-recent-sync.timer" "$config/systemd/user/icloud-recent-sync.service"
fi
rm -f "$HOME/.local/bin/icloud-recent" "$HOME/.local/bin/icloud-recent-sync" "$HOME/.local/share/applications/icloud-recent.desktop"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$config/systemd/user" "$config/omarchy-icloud-photos"
ln -sf "$here/bin/omarchy-icloud-photos" "$HOME/.local/bin/omarchy-icloud-photos"
ln -sf "$here/bin/omarchy-icloud-photos-sync" "$HOME/.local/bin/omarchy-icloud-photos-sync"
# The desktop entry is copied, not linked, so the icon can get its absolute
# path. LAUNCHER_NAME in the config renames it in the app launcher.
LAUNCHER_NAME=""
[ -f "$config/omarchy-icloud-photos/config" ] && . "$config/omarchy-icloud-photos/config"
sed "s|@ICON@|$here/assets/icon.png|; s|^Name=.*|Name=${LAUNCHER_NAME:-Omarchy iCloud Photos}|" "$here/omarchy-icloud-photos.desktop" > "$HOME/.local/share/applications/omarchy-icloud-photos.desktop"
ln -sf "$here/systemd/omarchy-icloud-photos-sync.service" "$config/systemd/user/omarchy-icloud-photos-sync.service"
ln -sf "$here/systemd/omarchy-icloud-photos-sync.timer" "$config/systemd/user/omarchy-icloud-photos-sync.timer"

if [ ! -f "$config/omarchy-icloud-photos/config" ]; then
  cat > "$config/omarchy-icloud-photos/config" <<CFG
# omarchy-icloud-photos configuration, sourced by omarchy-icloud-photos-sync
# APPLE_ID is filled in by the sign-in card in the app.
LIBRARY=\$HOME/Pictures/iCloud
DAYS=7
CFG
  echo "Start omarchy-icloud-photos and sign in with your Apple ID."
fi

# The trash helper talks to iCloud through pyicloud, which comes with the
# icloudpd sources. It lives in a virtualenv inside the repository.
# icloudpd's Python sources want 3.10 up to 3.13. Use the system python when
# it fits, otherwise a 3.13 from mise (installed on demand, no root needed).
python_ok() { "$1" -c 'import sys; sys.exit(0 if (3, 10) <= sys.version_info[:2] <= (3, 13) else 1)' 2>/dev/null; }
if [ ! -x "$here/.venv/bin/python" ]; then
  py=""
  for cand in python3 "$HOME"/.local/share/mise/installs/python/3.13*/bin/python3 "$HOME"/.local/share/mise/installs/python/3.12*/bin/python3; do
    if command -v "$cand" >/dev/null && python_ok "$cand"; then py="$cand"; break; fi
  done
  if [ -z "$py" ] && command -v mise >/dev/null; then
    echo "installing python 3.13 with mise for the iCloud helper…"
    mise install python@3.13 >/dev/null
    py="$(mise where python@3.13)/bin/python3"
  fi
  [ -n "$py" ] && python_ok "$py" || { echo "need a python between 3.10 and 3.13 for the iCloud helper (mise install python@3.13)" >&2; exit 1; }
  "$py" -m venv "$here/.venv"
  "$here/.venv/bin/pip" install -q "git+https://github.com/icloud-photos-downloader/icloud_photos_downloader@v$ICLOUDPD_VERSION"
fi

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
systemctl --user daemon-reload
systemctl --user enable --now omarchy-icloud-photos-sync.timer
echo "installed; next sync: $(systemctl --user list-timers omarchy-icloud-photos-sync.timer --no-pager | sed -n 2p | awk '{print $1, $2, $3}')"
