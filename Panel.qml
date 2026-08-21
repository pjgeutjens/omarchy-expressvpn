import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "." as ExpressVpnCore

Panel {
  id: root
  moduleName: "io.github.pjgeutjens.expressvpn"
  ipcTarget: "io.github.pjgeutjens.expressvpn"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property string locationQuery: ""
  property int locationIndex: 0
  property string focusSection: "header"
  property bool cursorActive: true
  property var favoriteRegions: []

  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property color dimForeground: Qt.darker(contentForeground, 1.5)
  readonly property color urgentForeground: bar ? bar.urgent : Color.urgent
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string toggleHint: ExpressVpnCore.VpnState.active
    ? "Disconnect ExpressVPN"
    : "Connect ExpressVPN"
  readonly property var visibleRegions: filteredRegions()
  readonly property var addressRows: ExpressVpnCore.VpnState.connected
      && ExpressVpnCore.VpnState.tunnelIp !== "" ? [
    { label: "Tunnel IP", value: ExpressVpnCore.VpnState.tunnelIp }
  ] : []

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function syncFavoriteRegions() {
    var source = settings && settings.favoriteRegions instanceof Array
      ? settings.favoriteRegions
      : []
    favoriteRegions = source.slice()
  }

  function isFavorite(regionId) {
    return favoriteRegions.indexOf(String(regionId || "")) !== -1
  }

  function isSmartLocation(regionId) {
    return String(regionId || "").toLowerCase() === "smart"
  }

  function regionLabel(regionId) {
    return isSmartLocation(regionId)
      ? "Fastest server"
      : ExpressVpnCore.VpnState.formatRegion(regionId)
  }

  function filteredRegions() {
    var query = String(locationQuery || "").trim().toLowerCase()
    var available = ExpressVpnCore.VpnState.regions || []
    var result = []
    var seen = ({})

    function matches(regionId) {
      if (query === "") return true
      var label = root.regionLabel(regionId).toLowerCase()
      if (root.isSmartLocation(regionId)) label += " smart location"
      return label.indexOf(query) !== -1 || String(regionId).toLowerCase().indexOf(query) !== -1
    }

    if (ExpressVpnCore.VpnState.installed && matches("smart")) {
      result.push("smart")
      seen.smart = true
    }

    for (var i = 0; i < favoriteRegions.length; i++) {
      var favorite = String(favoriteRegions[i] || "")
      if (favorite !== "" && available.indexOf(favorite) !== -1 && matches(favorite)) {
        result.push(favorite)
        seen[favorite] = true
      }
    }

    if (query === "") return result

    for (var j = 0; j < available.length; j++) {
      var regionId = String(available[j] || "")
      if (regionId !== "" && !seen[regionId] && matches(regionId)) result.push(regionId)
    }
    return result
  }

  function persistFavorites(next) {
    favoriteRegions = next
    if (!root.bar || !root.bar.shell || typeof root.bar.shell.updateEntryInline !== "function") return
    var entry = { id: root.moduleName }
    for (var key in settings) if (key !== "id") entry[key] = settings[key]
    entry.favoriteRegions = next
    root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function toggleFavorite(regionId) {
    var target = String(regionId || "")
    if (target === "" || isSmartLocation(target)) return
    var next = []
    var found = false
    for (var i = 0; i < favoriteRegions.length; i++) {
      var current = String(favoriteRegions[i] || "")
      if (current === target) found = true
      else if (current !== "" && next.indexOf(current) === -1) next.push(current)
    }
    if (!found) next.unshift(target)
    persistFavorites(next)
    clampLocationIndex()
  }

  function selectRegion(regionId) {
    ExpressVpnCore.VpnState.connectTo(regionId)
  }

  function clampLocationIndex() {
    locationIndex = Math.max(0, Math.min(locationIndex, Math.max(0, visibleRegions.length - 1)))
  }

  function focusHeader() {
    cursorActive = true
    focusSection = "header"
    keyCatcher.forceActiveFocus()
  }

  function focusLocation(index) {
    cursorActive = true
    focusSection = "locations"
    locationIndex = Math.max(0, Math.min(Number(index), Math.max(0, visibleRegions.length - 1)))
    keyCatcher.forceActiveFocus()
    Qt.callLater(function() { locationList.positionViewAtIndex(locationIndex, ListView.Contain) })
  }

  function moveCursor(direction) {
    cursorActive = true
    if (visibleRegions.length === 0) {
      focusSection = "header"
      return
    }
    if (focusSection === "header") {
      if (direction > 0) focusLocation(locationIndex)
      return
    }
    if (direction < 0 && locationIndex === 0) {
      focusHeader()
      return
    }
    locationIndex = (locationIndex + direction + visibleRegions.length) % visibleRegions.length
    Qt.callLater(function() { locationList.positionViewAtIndex(locationIndex, ListView.Contain) })
  }

  function activateCursor() {
    if (focusSection === "locations" && visibleRegions.length > 0)
      selectRegion(visibleRegions[locationIndex])
    else
      ExpressVpnCore.VpnState.toggle()
  }

  function focusSearch() {
    searchField.forceActiveFocus()
    searchField.selectAll()
  }

  onSettingsChanged: syncFavoriteRegions()
  onVisibleRegionsChanged: clampLocationIndex()
  Component.onCompleted: syncFavoriteRegions()

  onOpenedChanged: if (opened) {
    ExpressVpnCore.VpnState.refresh()
    ExpressVpnCore.VpnState.refreshRegions()
    cursorActive = true
    focusSection = "header"
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Connections {
    target: ExpressVpnCore.VpnState
    function onRegionsChanged() { root.clampLocationIndex() }
  }

  Component {
    id: vpnIcon
    ExpressVpnCore.ExpressVpnIcon {
      iconSize: Style.font.display
      iconColor: root.contentForeground
      fallbackColor: root.contentForeground
      fallbackFontFamily: root.contentFontFamily
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(650))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: searchField.activeFocus
      onMoveRequested: function(dx, dy) { if (dy !== 0) root.moveCursor(dy) }
      onActivateRequested: root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (text === "t" || text === "T") ExpressVpnCore.VpnState.toggle()
        else if (text === "r" || text === "R") {
          ExpressVpnCore.VpnState.refresh()
          ExpressVpnCore.VpnState.refreshRegions()
        } else if (text === "f" || text === "F") {
          if (root.focusSection === "locations" && root.visibleRegions.length > 0)
            root.toggleFavorite(root.visibleRegions[root.locationIndex])
        } else if (text === "/") {
          root.focusSearch()
        }
      }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(12)

        Item {
          id: heroContainer
          width: parent.width
          implicitHeight: hero.implicitHeight

          PanelHero {
            id: hero
            width: parent.width
            iconComponent: vpnIcon
            title: "ExpressVPN"
            meta: ExpressVpnCore.VpnState.markupSafeText(
              ExpressVpnCore.VpnState.statusText + " · " + ExpressVpnCore.VpnState.locationText
            )
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily

            trailingControl: Component {
              ToggleSwitch {
                id: powerSwitch
                visible: ExpressVpnCore.VpnState.installed
                checked: ExpressVpnCore.VpnState.active
                busy: ExpressVpnCore.VpnState.busy
                hasCursor: root.cursorActive && root.focusSection === "header"
                foreground: hero.foreground
                onHovered: function(on) { if (on) root.focusHeader() }
                onToggled: ExpressVpnCore.VpnState.toggle()

                PanelToolTip {
                  visible: powerSwitch.containsMouse
                  text: root.toggleHint
                  fontFamily: hero.fontFamily
                }
              }
            }
          }
        }

        Text {
          visible: ExpressVpnCore.VpnState.lastError !== ""
          width: parent.width
          text: ExpressVpnCore.VpnState.lastError
          textFormat: Text.PlainText
          color: root.urgentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Column {
          visible: root.addressRows.length > 0
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: root.addressRows

            delegate: Item {
              required property var modelData
              width: parent.width
              implicitHeight: Math.max(addressLabel.implicitHeight, addressValue.implicitHeight)

              Text {
                id: addressLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                textFormat: Text.PlainText
                color: root.dimForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
              }

              Text {
                id: addressValue
                anchors.left: addressLabel.right
                anchors.leftMargin: Style.space(12)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.value
                textFormat: Text.PlainText
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideMiddle
              }
            }
          }
        }

        PanelSeparator {
          foreground: root.contentForeground
        }

        Item {
          width: parent.width
          implicitHeight: Math.max(locationHeader.implicitHeight, favoriteSummary.implicitHeight)

          PanelSectionHeader {
            id: locationHeader
            text: "LOCATIONS"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            id: favoriteSummary
            text: root.favoriteRegions.length === 0
              ? "Type to find locations"
              : root.favoriteRegions.length + (root.favoriteRegions.length === 1 ? " favorite" : " favorites")
            textFormat: Text.PlainText
            color: root.dimForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        TextField {
          id: searchField
          width: parent.width
          text: root.locationQuery
          placeholderText: "Search all locations"
          foreground: root.contentForeground
          font.family: root.contentFontFamily
          onTextChanged: {
            root.locationQuery = text
            root.locationIndex = 0
          }
          onAccepted: {
            if (root.visibleRegions.length > 0) root.selectRegion(root.visibleRegions[root.locationIndex])
            root.focusLocation(root.locationIndex)
          }
          Keys.onDownPressed: function(event) {
            root.focusLocation(Math.min(root.locationIndex + 1, root.visibleRegions.length - 1))
            event.accepted = true
          }
          Keys.onUpPressed: function(event) {
            root.focusLocation(Math.max(0, root.locationIndex - 1))
            event.accepted = true
          }
          Keys.onEscapePressed: {
            text = ""
            root.focusHeader()
          }
        }

        Text {
          visible: ExpressVpnCore.VpnState.loadingRegions
          width: parent.width
          text: "Loading ExpressVPN locations…"
          textFormat: Text.PlainText
          color: root.dimForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          visible: !ExpressVpnCore.VpnState.loadingRegions && root.visibleRegions.length === 0
          width: parent.width
          text: root.locationQuery === ""
            ? "No favorites yet. Type a location, then star it."
            : "No matching locations."
          textFormat: Text.PlainText
          color: root.dimForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
        }

        ListView {
          id: locationList
          visible: root.visibleRegions.length > 0
          width: parent.width
          height: Math.min(contentHeight, Style.space(240))
          clip: true
          spacing: Style.space(3)
          model: root.visibleRegions
          currentIndex: root.locationIndex
          boundsBehavior: Flickable.StopAtBounds

          delegate: CursorSurface {
            id: locationRow
            required property string modelData
            required property int index
            width: locationList.width
            implicitHeight: Math.max(locationLabel.implicitHeight, favoriteStar.implicitHeight) + Style.space(12)
            foreground: root.contentForeground
            hasCursor: root.cursorActive && root.focusSection === "locations" && root.locationIndex === index

            MouseArea {
              anchors.fill: parent
              anchors.rightMargin: favoriteStar.width + Style.space(12)
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: !ExpressVpnCore.VpnState.busy
              onEntered: root.focusLocation(locationRow.index)
              onClicked: root.selectRegion(locationRow.modelData)
            }

            Text {
              id: locationLabel
              anchors.left: parent.left
              anchors.leftMargin: Style.space(12)
              anchors.right: currentMark.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: root.regionLabel(locationRow.modelData)
              textFormat: Text.PlainText
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.bold: root.isSmartLocation(locationRow.modelData) || root.isFavorite(locationRow.modelData)
              elide: Text.ElideRight
            }

            Text {
              id: currentMark
              anchors.right: favoriteStar.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              text: ExpressVpnCore.VpnState.region === locationRow.modelData ? "●" : ""
              textFormat: Text.PlainText
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              id: favoriteStar
              width: Style.space(34)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              text: root.isSmartLocation(locationRow.modelData)
                ? "⚡"
                : (root.isFavorite(locationRow.modelData) ? "★" : "☆")
              textFormat: Text.PlainText
              color: root.isSmartLocation(locationRow.modelData)
                ? root.dimForeground
                : (root.isFavorite(locationRow.modelData) ? Color.accent : root.dimForeground)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter

              MouseArea {
                anchors.fill: parent
                enabled: !root.isSmartLocation(locationRow.modelData)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.focusLocation(locationRow.index)
                onClicked: root.toggleFavorite(locationRow.modelData)
              }
            }
          }
        }

        Text {
          width: parent.width
          text: "J/K move · Enter connect · F star · / search · T toggle"
          textFormat: Text.PlainText
          color: root.dimForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }
      }
    }
  }
}
