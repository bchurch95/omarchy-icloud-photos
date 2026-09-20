# Recent iCloud Photos

The last week of your iCloud Photos library as a native window on Omarchy. A bash script pulls new photos and videos with [icloudpd](https://github.com/icloud-photos-downloader/icloud_photos_downloader) and builds a thumbnail index; a small [Quickshell](https://quickshell.org) app renders it with the current Omarchy theme.

The sync can only download: icloudpd runs in its default copy mode, without `--auto-delete` or `--keep-icloud-recent-days`. The one thing that writes to iCloud is the `d` key, which moves a single item to Recently Deleted, the same 30-day bin the Photos app uses. There is no bulk delete and nothing can empty that bin.

## Install

```bash
yay -S quickshell imagemagick ffmpeg jq wl-clipboard
# icloudpd: AUR package icloudpd-bin, or drop the release binary in ~/.local/bin
git clone git@github.com:jankeesvw/recent-icloud-photos.git ~/Documents/github.com/jankeesvw/recent-icloud-photos
~/Documents/github.com/jankeesvw/recent-icloud-photos/install.sh
```

The installer symlinks the launcher and sync script into `~/.local/bin`, adds a desktop entry, and enables a systemd user timer that syncs every 30 minutes. Start the app with `icloud-recent`, or from the app launcher as "Recent iCloud Photos". The first run shows a sign-in card: Apple ID, password, then the six-digit code Apple pushes to your devices. The password is only used to open the session and is not stored; the session lands in `~/.config/icloudpd` where icloudpd finds it, and lasts a few months. When it expires the card comes back with the Apple ID filled in.

The same session can also be made on the command line, which is handy on a headless box:

```bash
icloudpd --auth-only --username you@example.com --cookie-directory ~/.config/icloudpd
```

## Configuration

`~/.config/icloud-recent/config` is sourced by the sync script:

| Variable | Default | Meaning |
|---|---|---|
| `APPLE_ID` | set by the sign-in card | Apple ID to log in with |
| `LIBRARY` | `~/Pictures/iCloud` | Where originals land, as `YYYY/MM/` folders |
| `DAYS` | `7` | How many days the window shows |
| `RECENT_LIMIT` | `500` | Newest assets icloudpd walks per run |
| `COOKIES` | `~/.config/icloudpd` | icloudpd session directory |
| `CACHE` | `~/.cache/icloud-recent` | Thumbnails, previews, SDR video copies, index |

## Keys

In the grid a click selects and a click on the selected item opens it. Hovering does nothing. Shift-click or shift with the movement keys selects a range, ctrl-click adds or removes one item, ctrl-a selects everything and Esc clears. With several items selected, `y` copies them as a file list (file managers paste copies, chat apps attach them), `Y` copies their paths one per line and `d` moves them all to Recently Deleted, with one Undo for the whole batch. Clicking the filename in the footer copies the full path.

| Key | Grid | Viewer |
|---|---|---|
| `h` `j` `k` `l`, arrows | move | previous / next |
| `Enter`, `Space` | open viewer | pause or resume a video, show or hide the Live Photo clip |
| `←` / `→` | move | seek 5 s while a video is on screen (the timeline can be clicked and dragged too) |
| `o` | open in default app | same |
| `y` / `Y` | copy image / copy path | same |
| `d` | move to Recently Deleted (asks first) | same |
| `u` | undo the last delete | same |
| `r` | sync now | |
| `-` / `+` | smaller / larger thumbnails (or the slider in the footer) | |
| `g` / `G` | oldest / newest | |
| `Esc`, `q` | quit | back to grid |

## How it works

`bin/icloud-recent-sync` runs icloudpd with `--recent 500 --skip-created-before <DAYS+1>d`, then indexes every file in the library newer than DAYS days. Capture time comes from the file's mtime, which icloudpd sets to the asset's creation date. For each item it caches a 400 px thumbnail and, for HEIC, a 2200 px JPEG preview, since Qt cannot decode HEIC. A Live Photo's `_HEVC.MOV` companion is folded into its still. iPhone videos are HLG BT.2020 and Qt's player does no tone mapping, so HDR videos get a tone-mapped SDR H.264 copy in the cache for playback; the original stays untouched and is what `o` and `Y` refer to.

Items are ordered oldest to newest, so the grid opens scrolled to the bottom like the Photos app on the phone and new items appear at the end. Signing in and deleting go through `bin/icloud_helper.py`, on the pyicloud module that ships with icloudpd, in a virtualenv the installer creates under `.venv`. It looks the asset up by filename and capture time among the newest items, flips the record's `isDeleted` flag (what the Photos app does), and moves the local files into `~/.cache/icloud-recent/trash/<key>/` with a manifest. Undo, from the toast button or `u`, flips the flag back and moves the files home. Recently Deleted on the phone remains the safety net for 30 days.

The result of a sync is `~/.cache/icloud-recent/index.json` plus `status.json`; the QML watches both and re-renders when they change, so a sync started by the timer shows up in an open window.

## Files

```
bin/icloud-recent          launcher: quickshell -p ui/shell.qml
bin/icloud-recent-sync     download + index, safe to run any time
bin/icloud-recent-helper   wrapper that runs icloud_helper.py in .venv
bin/icloud_helper.py       login, and find / delete / restore one asset
ui/Login.qml               sign-in card (Apple ID, password, 2FA code)
ui/ConfirmDelete.qml       the "move to Recently Deleted?" dialog
ui/shell.qml               window, grid, key handling
ui/Thumb.qml               one grid cell
ui/Viewer.qml              full-window still / video
ui/Theme.qml               colours from ~/.local/state/omarchy/current/theme/colors.toml
systemd/                   user service + 30 min timer
install.sh                 symlinks everything into place
```
