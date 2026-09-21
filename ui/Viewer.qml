import QtQuick
import QtMultimedia

// Full-window view of one item: a still, a video, or a Live Photo whose
// motion half plays on Space. Navigation and closing are handled by the
// parent's key handler; this renders and drives playback.
Rectangle {
  id: root

  required property var theme
  property var item: null
  // Whether the moving picture is on screen: always for a video, toggled
  // for a Live Photo.
  property bool videoShown: false
  readonly property bool playing: video.playbackState === MediaPlayer.PlayingState
  readonly property bool hasVideo: item !== null && !!item.video

  signal requestClose()
  signal requestNext()
  signal requestPrev()
  signal requestCopyPath()
  signal requestSave()

  color: theme.darkerBackground
  visible: item !== null
  focus: false

  onItemChanged: {
    videoShown = item !== null && item.kind === "video";
  }

  // Space: pause or resume a video; for a Live Photo, play the clip once.
  function togglePlay() {
    if (!hasVideo) return;
    if (item.kind === "live") {
      playLive();
      return;
    }
    if (playing) video.pause(); else video.play();
  }

  // The moving half of a Live Photo plays once and the still comes back,
  // like pressing the picture on the phone.
  function playLive() {
    if (!item || item.kind !== "live" || videoShown) return;
    videoShown = true;
  }

  function seekBy(ms) {
    if (!videoShown || video.duration <= 0) return;
    video.seek(Math.max(0, Math.min(video.duration, video.position + ms)));
  }

  function seekTo(fraction) {
    if (video.duration <= 0) return;
    video.seek(Math.max(0, Math.min(video.duration, fraction * video.duration)));
  }

  function fmt(ms) {
    var s = Math.floor(Math.max(0, ms) / 1000);
    var m = Math.floor(s / 60);
    var r = s % 60;
    return m + ":" + (r < 10 ? "0" : "") + r;
  }

  // The grid sits underneath and selects on hover, so swallow every mouse
  // event here or moving the pointer would silently switch the photo.
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.AllButtons
    onWheel: wheel => {
      if (wheel.angleDelta.y < 0) root.requestNext(); else root.requestPrev();
      wheel.accepted = true;
    }
  }

  Item {
    id: frame
    anchors.fill: parent
    anchors.margins: 12
    anchors.bottomMargin: (root.videoShown && item && item.kind === "video") ? 56 + 44 : 56
  }

  Image {
    id: still
    anchors.fill: frame
    source: (item && item.kind !== "video") ? "file://" + item.preview : ""
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    autoTransform: true
    smooth: true
    mipmap: true
    cache: false
    visible: !root.videoShown
    sourceSize.width: 2400
  }

  Text {
    anchors.centerIn: still
    visible: still.status === Image.Loading
    text: "…"
    color: theme.darkForeground
    font.family: theme.fontFamily
    font.pixelSize: 28
  }

  Video {
    id: video
    anchors.fill: frame
    source: (root.videoShown && item && item.video) ? "file://" + item.video : ""
    fillMode: VideoOutput.PreserveAspectFit
    loops: (item && item.kind === "live") ? 1 : MediaPlayer.Infinite
    visible: root.videoShown
    onSourceChanged: if (source != "") play()
    // A Live Photo clip ends by itself: back to the still.
    onStopped: if (item && item.kind === "live") root.videoShown = false

    // Click the picture to pause or resume.
    MouseArea {
      anchors.fill: parent
      onClicked: root.togglePlay()
    }
  }

  // ---- Live Photo button ---------------------------------------------------
  // A small round button on the picture, like the phone has: tap to play the
  // moving half, tap again to go back to the still. Space does the same.
  Rectangle {
    visible: item !== null && item.kind === "live"
    anchors.left: frame.left
    anchors.bottom: frame.bottom
    anchors.margins: 16
    width: 40; height: 40; radius: 20
    color: root.videoShown ? theme.accent : Qt.rgba(0, 0, 0, 0.55)
    border.color: root.videoShown ? theme.accent : Qt.rgba(1, 1, 1, 0.6)
    border.width: 1.5
    Text {
      anchors.centerIn: parent
      text: "\uf192"
      color: root.videoShown ? theme.darkerBackground : "white"
      font.family: theme.fontFamily
      font.pixelSize: 17
    }
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.togglePlay()
    }
    Text {
      anchors.left: parent.right
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: "LIVE"
      color: "white"
      font.family: theme.fontFamily
      font.pixelSize: 11
      font.bold: true
      style: Text.Outline
      styleColor: Qt.rgba(0, 0, 0, 0.7)
    }
  }

  // ---- Live Photo button ---------------------------------------------------
  // The small round button on the picture: move the pointer over it and the
  // clip plays once, then the still is back. Space does the same.
  Rectangle {
    visible: item !== null && item.kind === "live"
    anchors.left: frame.left
    anchors.bottom: frame.bottom
    anchors.margins: 16
    width: 36; height: 36; radius: 18
    color: root.videoShown ? theme.accent : Qt.rgba(0, 0, 0, 0.55)
    border.color: root.videoShown ? theme.accent : Qt.rgba(1, 1, 1, 0.7)
    border.width: 1.5
    Text {
      anchors.centerIn: parent
      text: "\uf192"
      color: root.videoShown ? theme.darkerBackground : "white"
      font.family: theme.fontFamily
      font.pixelSize: 16
    }
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: root.playLive()
      onClicked: root.playLive()
    }
    Text {
      anchors.left: parent.right
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      text: "LIVE"
      color: "white"
      font.family: theme.fontFamily
      font.pixelSize: 11
      font.bold: true
      style: Text.Outline
      styleColor: Qt.rgba(0, 0, 0, 0.7)
    }
  }

  // ---- Scrubber ----------------------------------------------------------
  Rectangle {
    id: scrubber
    visible: root.videoShown && item && item.kind === "video"
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: caption.top
    height: 44
    color: theme.darkerBackground

    Row {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      spacing: 14

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; radius: 6
        color: playArea.containsMouse ? theme.lighterBackground : "transparent"
        Text {
          anchors.centerIn: parent
          text: root.playing ? "" : ""
          color: theme.brightForeground
          font.family: theme.fontFamily
          font.pixelSize: 13
        }
        MouseArea {
          id: playArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.togglePlay()
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.fmt(video.position)
        color: theme.foreground
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize - 1
        width: 40
      }

      // The timeline: click or drag anywhere on it to seek.
      Item {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 30 - 40 - 40 - 14 * 4
        height: 24
        readonly property real fraction: video.duration > 0 ? video.position / video.duration : 0

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: 4
          radius: 2
          color: theme.lighterBackground
          Rectangle {
            width: track.fraction * parent.width
            height: parent.height
            radius: 2
            color: theme.accent
          }
        }
        Rectangle {
          x: track.fraction * (track.width - width)
          anchors.verticalCenter: parent.verticalCenter
          width: trackArea.pressed || trackArea.containsMouse ? 14 : 10
          height: width
          radius: width / 2
          color: theme.brightForeground
          Behavior on width { NumberAnimation { duration: 80 } }
        }
        MouseArea {
          id: trackArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onPressed: mouse => root.seekTo(mouse.x / width)
          onPositionChanged: mouse => { if (pressed) root.seekTo(mouse.x / width); }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.fmt(video.duration)
        color: theme.darkForeground
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize - 1
        width: 40
        horizontalAlignment: Text.AlignRight
      }
    }
  }

  // ---- Caption: date, time, name and what the keys do ---------------------
  Rectangle {
    id: caption
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 48
    color: theme.darkBackground

    Row {
      id: captionLeft
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      spacing: 14

      Text {
        text: item ? root.longDate(item) : ""
        color: theme.brightForeground
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize
      }
      Text {
        text: item ? item.time : ""
        color: theme.foreground
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize
      }
      // The filename copies the full path, like in the grid's footer.
      Text {
        text: item ? item.name : ""
        color: nameArea.containsMouse ? theme.brightForeground : theme.darkForeground
        font.underline: nameArea.containsMouse
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize
        MouseArea {
          id: nameArea
          anchors.fill: parent
          anchors.margins: -4
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestCopyPath()
        }
      }
      Rectangle {
        visible: item && item.kind === "live"
        anchors.verticalCenter: parent.verticalCenter
        width: liveLabel.implicitWidth + 12
        height: 20
        radius: 4
        color: root.videoShown ? theme.accent : theme.lighterBackground
        Text {
          id: liveLabel
          anchors.centerIn: parent
          text: "LIVE"
          color: root.videoShown ? theme.darkerBackground : theme.foreground
          font.family: theme.fontFamily
          font.pixelSize: 11
          font.bold: true
        }
      }
    }

    Row {
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      spacing: 10

      // Only a nudge for the one key that is not obvious; `?` has the rest.
      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.hasVideo && !root.videoShown
        text: "space plays"
        color: theme.darkForeground
        font.family: theme.fontFamily
        font.pixelSize: theme.fontSize - 1
      }

      // Download: a copy of the original lands in ~/Downloads.
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: saveLabel.implicitWidth + 24
        height: 28
        radius: 6
        color: saveArea.containsMouse ? theme.lighterBackground : "transparent"
        border.color: theme.lighterBackground
        border.width: 1
        Row {
          id: saveLabel
          anchors.centerIn: parent
          spacing: 8
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf019"
            color: theme.foreground
            font.family: theme.fontFamily
            font.pixelSize: 12
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Download"
            color: theme.foreground
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSize - 1
          }
        }
        MouseArea {
          id: saveArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestSave()
        }
      }
    }
  }

  function longDate(it) {
    var d = new Date(it.ts * 1000);
    return d.toLocaleDateString(Qt.locale("en_GB"), "dddd d MMMM yyyy");
  }
}
