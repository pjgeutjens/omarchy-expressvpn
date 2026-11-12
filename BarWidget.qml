import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "." as ExpressVpnCore

BarWidget {
  id: root
  moduleName: "io.github.pjgeutjens.expressvpn"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "io.github.pjgeutjens.expressvpn"

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }

    function connect(): string {
      ExpressVpnCore.VpnState.connect()
      return ExpressVpnCore.VpnState.statusText
    }

    function connectTo(region: string): string {
      ExpressVpnCore.VpnState.connectTo(region)
      return ExpressVpnCore.VpnState.statusText
    }

    function disconnect(): string {
      ExpressVpnCore.VpnState.disconnect()
      return ExpressVpnCore.VpnState.statusText
    }

    function toggleVpn(): string {
      ExpressVpnCore.VpnState.toggle()
      return ExpressVpnCore.VpnState.statusText
    }

    function refresh(): string {
      ExpressVpnCore.VpnState.refresh()
      return ExpressVpnCore.VpnState.statusText
    }

    function status(): string {
      return JSON.stringify({
        installed: ExpressVpnCore.VpnState.installed,
        state: ExpressVpnCore.VpnState.connectionState,
        active: ExpressVpnCore.VpnState.active,
        location: ExpressVpnCore.VpnState.locationText,
        tunnelIp: ExpressVpnCore.VpnState.tunnelIp,
        error: ExpressVpnCore.VpnState.lastError
      })
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical
      ? -1
      : vpnIcon.implicitWidth + button.scaledHorizontalMargin * 2
    active: ExpressVpnCore.VpnState.active
    readonly property color statusIconColor: {
      if (!ExpressVpnCore.VpnState.installed)
        return Qt.darker(button.foreground, 1.8)
      if (ExpressVpnCore.VpnState.lastError !== "")
        return Color.urgent
      if (ExpressVpnCore.VpnState.connected)
        return button.activeColor
      if (ExpressVpnCore.VpnState.busy)
        return button.foreground
      return Qt.darker(button.foreground, 1.55)
    }
    tooltipText: ExpressVpnCore.VpnState.markupSafeText(
      "ExpressVPN · " + ExpressVpnCore.VpnState.statusText
        + (ExpressVpnCore.VpnState.region === "" ? "" : " · " + ExpressVpnCore.VpnState.locationText)
    )

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) ExpressVpnCore.VpnState.toggle()
      else if (buttonCode === Qt.MiddleButton) ExpressVpnCore.VpnState.refresh()
      else root.toggle()
    }

    ExpressVpnCore.ExpressVpnIcon {
      id: vpnIcon
      anchors.centerIn: parent
      iconSize: Style.bar.iconFont
      iconColor: button.statusIconColor
      maskThresholdMin: 0.48
      fallbackColor: button.statusIconColor
      fallbackFontFamily: button.fontFamily

      Behavior on iconColor {
        ColorAnimation { duration: Style.duration(160) }
      }
      Behavior on fallbackColor {
        ColorAnimation { duration: Style.duration(160) }
      }
    }

    SequentialAnimation {
      running: ExpressVpnCore.VpnState.busy && !Style.reduceMotion
      loops: Animation.Infinite
      onRunningChanged: if (!running) vpnIcon.opacity = 1.0

      NumberAnimation {
        target: vpnIcon
        property: "opacity"
        from: 1.0
        to: 0.35
        duration: Style.duration(500)
        easing.type: Easing.InOutSine
      }
      NumberAnimation {
        target: vpnIcon
        property: "opacity"
        to: 1.0
        duration: Style.duration(500)
        easing.type: Easing.InOutSine
      }
    }
  }
}
