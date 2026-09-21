import QtQuick

// One square in the grid. Shows the cached thumbnail, a play badge with the
// duration for videos and a LIVE badge for Live Photos.
Rectangle {
  id: root

  required property var theme
  property var item: null
  property int index: -1
  property int size: 176
  property bool selected: false
  property bool checked: false

  signal clicked(int modifiers)

  width: size
  height: size
  radius: 6
  color: theme.darkBackground
  border.width: (selected || checked) ? 3 : 0
  border.color: selected ? theme.accent : Qt.darker(theme.accent, 1.4)

  Image {
    anchors.fill: parent
    anchors.margins: (root.selected || root.checked) ? 3 : 0
    source: item ? "file://" + item.thumb : ""
    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: 400
    sourceSize.height: 400
    smooth: true
    layer.enabled: true
    layer.effect: null
  }

  function fmtDuration(s) {
    s = Math.round(s || 0);
    var m = Math.floor(s / 60);
    var r = s % 60;
    return m + ":" + (r < 10 ? "0" : "") + r;
  }

  Rectangle {
    visible: item && item.kind === "video"
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: 8
    width: durationText.implicitWidth + 22
    height: 22
    radius: 4
    color: Qt.rgba(0, 0, 0, 0.6)
    Row {
      anchors.centerIn: parent
      spacing: 5
      Text {
        text: ""
        color: "white"
        font.family: theme.fontFamily
        font.pixelSize: 9
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: durationText
        text: item ? root.fmtDuration(item.duration) : ""
        color: "white"
        font.family: theme.fontFamily
        font.pixelSize: 11
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  // Live Photo mark, the same circle the phone shows top-left.
  Row {
    visible: item && item.kind === "live"
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: 8
    spacing: 5
    Rectangle {
      width: 22; height: 22; radius: 11
      color: Qt.rgba(0, 0, 0, 0.6)
      border.color: Qt.rgba(1, 1, 1, 0.8)
      border.width: 1
      Rectangle {
        anchors.centerIn: parent
        width: 11; height: 11; radius: 5.5
        color: "transparent"
        border.width: 1
        border.color: "white"
      }
      Rectangle {
        anchors.centerIn: parent
        width: 4; height: 4; radius: 2
        color: "white"
      }
    }
  }

  // Check mark for items in a multi-selection.
  Rectangle {
    visible: root.checked
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 8
    width: 22; height: 22; radius: 11
    color: theme.accent
    Text {
      anchors.centerIn: parent
      text: "\uf00c"
      color: theme.darkerBackground
      font.family: theme.fontFamily
      font.pixelSize: 11
      font.bold: true
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => root.clicked(mouse.modifiers)
  }
}
