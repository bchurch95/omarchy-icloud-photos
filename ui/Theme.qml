import QtQuick

// Colours from Omarchy's current theme (colors.toml), with the Tokyo Night
// palette as fallback until the file has been read.
QtObject {
  id: root

  property color background: "#1a1b26"
  property color darkBackground: "#13141c"
  property color darkerBackground: "#0e0e14"
  property color lighterBackground: "#24283b"
  property color foreground: "#a9b1d6"
  property color darkForeground: "#565f89"
  property color brightForeground: "#c0caf5"
  property color accent: "#7aa2f7"
  property color selection: "#292e42"
  property color muted: "#414868"
  property color red: "#f7768e"
  property color yellow: "#e0af68"
  property color green: "#9ece6a"

  property string fontFamily: "CaskaydiaMono Nerd Font"
  property int fontSize: 13

  function apply(raw) {
    var lines = String(raw || "").split("\n");
    var c = {};
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*([A-Za-z0-9_]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/);
      if (m) c[m[1]] = m[2];
    }
    if (c.background) background = c.background;
    if (c.dark_background) darkBackground = c.dark_background;
    if (c.darker_background) darkerBackground = c.darker_background;
    if (c.lighter_background) lighterBackground = c.lighter_background;
    if (c.foreground) foreground = c.foreground;
    if (c.dark_foreground) darkForeground = c.dark_foreground;
    if (c.bright_foreground) brightForeground = c.bright_foreground;
    if (c.accent) accent = c.accent;
    if (c.selection) selection = c.selection;
    if (c.muted) muted = c.muted;
    if (c.red) red = c.red;
    if (c.yellow) yellow = c.yellow;
    if (c.green) green = c.green;
  }
}
