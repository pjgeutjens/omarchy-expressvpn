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
      : vpnRow.implicitWidth + button.scaledHorizontalMargin * 2
    active: ExpressVpnCore.VpnState.active
    tooltipText: ExpressVpnCore.VpnState.markupSafeText(
      "ExpressVPN · " + ExpressVpnCore.VpnState.statusText
        + (ExpressVpnCore.VpnState.region === "" ? "" : " · " + ExpressVpnCore.VpnState.locationText)
    )

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) ExpressVpnCore.VpnState.toggle()
      else if (buttonCode === Qt.MiddleButton) ExpressVpnCore.VpnState.refresh()
      else root.toggle()
    }

    Row {
      id: vpnRow
      anchors.centerIn: parent
      spacing: Style.space(4)

      ExpressVpnCore.ExpressVpnIcon {
        iconSize: Style.bar.iconFont
        iconColor: button.foreground
        maskThresholdMin: 0.48
        fallbackColor: button.foreground
        fallbackFontFamily: button.fontFamily
        anchors.verticalCenter: parent.verticalCenter
      }

      Rectangle {
        width: Style.space(4)
        height: width
        radius: width / 2
        color: ExpressVpnCore.VpnState.connected
          ? button.activeColor
          : ExpressVpnCore.VpnState.transitional
            ? button.foreground
            : Qt.darker(button.foreground, 1.8)
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on opacity {
          running: ExpressVpnCore.VpnState.transitional
          loops: Animation.Infinite
          NumberAnimation { to: 0.3; duration: 500 }
          NumberAnimation { to: 1.0; duration: 500 }
        }
      }
    }
  }
}
