import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.iconLarge
  property bool colorized: true
  property color iconColor: Color.foreground
  property color fallbackColor: Color.foreground
  property string fallbackFontFamily: Style.font.family

  implicitWidth: iconSize
  implicitHeight: iconSize

  // The client ships the mark as a pixmap. This shell's icon theme does not
  // index /usr/share/pixmaps, so a theme lookup comes back empty.
  readonly property url logoUrl: "file:///usr/share/pixmaps/expressvpn.png"
  readonly property bool logoReady: logo.status === Image.Ready
  readonly property bool logoPending: logo.status === Image.Loading

  Item {
    id: mark
    anchors.centerIn: parent
    width: root.iconSize
    height: root.iconSize

    Image {
      id: logo
      anchors.fill: parent
      source: root.logoUrl
      sourceSize.width: Math.ceil(root.iconSize * 2)
      sourceSize.height: Math.ceil(root.iconSize * 2)
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      cache: true
      // Drawn into a layer the mask can sample. opacity 0 still renders that
      // layer; visible: false leaves it empty and the tint becomes a square.
      opacity: root.colorized ? 0 : 1
      visible: root.logoReady
      layer.enabled: root.colorized && root.logoReady
    }

    // Paint the status color through the mark's alpha. MultiEffect colorization
    // keeps the dark red, so the mark disappears on the bar.
    Rectangle {
      anchors.fill: parent
      color: root.iconColor
      visible: root.colorized && root.logoReady
      layer.enabled: visible
      layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: logo
        maskThresholdMin: 0.4
        maskSpreadAtMin: 1.0
      }
    }
  }

  Text {
    anchors.centerIn: parent
    visible: !root.logoReady && !root.logoPending
    text: "VPN"
    textFormat: Text.PlainText
    color: root.fallbackColor
    font.family: root.fallbackFontFamily
    font.pixelSize: Math.max(8, root.iconSize * 0.55)
    font.bold: true
    renderType: Text.NativeRendering
  }
}
