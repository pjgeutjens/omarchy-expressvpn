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

  // Theme icon first. The pixmap is only for themes that do not index
  // /usr/share/pixmaps, where the lookup comes back empty.
  readonly property string themeIcon: Quickshell.iconPath("expressvpn", true)
  readonly property string pixmapIcon: "file:///usr/share/pixmaps/expressvpn.png"
  property string iconSource: themeIcon !== "" ? themeIcon : pixmapIcon
  property bool triedPixmap: themeIcon === ""
  property bool sourcesExhausted: false
  readonly property bool logoReady: !sourcesExhausted && logo.status === Image.Ready
  readonly property bool logoPending: !sourcesExhausted && iconSource !== ""
    && (logo.status === Image.Loading || logo.status === Image.Null)

  Item {
    id: mark
    anchors.centerIn: parent
    width: root.iconSize
    height: root.iconSize

    Image {
      id: logo
      anchors.fill: parent
      source: root.sourcesExhausted ? "" : root.iconSource
      sourceSize.width: Math.ceil(root.iconSize * 2)
      sourceSize.height: Math.ceil(root.iconSize * 2)
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      cache: true
      onStatusChanged: {
        if (status !== Image.Error || root.sourcesExhausted) return
        if (String(source) !== root.iconSource) return
        if (!root.triedPixmap) {
          root.triedPixmap = true
          Qt.callLater(function() { root.iconSource = root.pixmapIcon })
          return
        }
        root.sourcesExhausted = true
      }
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
