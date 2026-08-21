import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.iconLarge
  property bool colorized: true
  property color iconColor: Color.foreground
  property real maskThresholdMin: 0.0
  property real maskThresholdMax: 1.0
  property color fallbackColor: Color.foreground
  property string fallbackFontFamily: Style.font.family

  implicitWidth: iconSize
  implicitHeight: iconSize

  Image {
    id: logo
    anchors.fill: parent
    source: Quickshell.iconPath("expressvpn", true)
    sourceSize.width: Math.ceil(root.iconSize * 2)
    sourceSize.height: Math.ceil(root.iconSize * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    cache: true
    visible: !root.colorized
    layer.enabled: root.colorized
  }

  Rectangle {
    id: tintSource
    anchors.fill: logo
    color: root.iconColor
    visible: false
    layer.enabled: root.colorized
  }

  MultiEffect {
    anchors.fill: logo
    source: tintSource
    visible: root.colorized
    maskEnabled: true
    maskSource: logo
    maskThresholdMin: root.maskThresholdMin
    maskThresholdMax: root.maskThresholdMax
  }

  Text {
    anchors.centerIn: parent
    visible: logo.source === "" || logo.status === Image.Error
    text: "VPN"
    color: root.fallbackColor
    font.family: root.fallbackFontFamily
    font.pixelSize: Math.max(8, root.iconSize * 0.55)
    font.bold: true
    renderType: Text.NativeRendering
  }
}
