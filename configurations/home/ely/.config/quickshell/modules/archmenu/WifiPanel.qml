import "../.." as Config
import "../../services" as Services
import "../../widgets" as Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking

Rectangle {
    id: wifiPanel
    required property var menu

    function wifiSignalIcon(signal) {
        if (signal >= 80)
            return "signal_wifi_4_bar";
        if (signal >= 60)
            return "network_wifi_3_bar";
        if (signal >= 35)
            return "network_wifi_2_bar";
        if (signal > 0)
            return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }

    function wifiSecurityIcon(security) {
        return security === WifiSecurityType.Open ? "lock_open" : "lock";
    }

    function focusPassword() {
        wifiPasswordField.forceActiveFocus();
    }
    visible: Services.WifiControl.expanded || Services.WifiControl.showPassword
    Layout.fillWidth: true
    implicitHeight: wifiColumn.implicitHeight + 20
    radius: Config.Theme.radiusControl
    color: wifiHover.hovered ? Config.Theme.alpha(Config.Theme.colTextSec, 0.18) : Config.Theme.alpha(Config.Theme.colTextSec, 0.1)

    HoverHandler { id: wifiHover }

    ColumnLayout {
        id: wifiColumn

        spacing: Config.Theme.spaceSm
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: wifiHeader.implicitHeight

            RowLayout {
                id: wifiHeader
                anchors.fill: parent

                Text {
                    text: Services.WifiControl.enabled ? "wifi" : "wifi_off"
                    color: Services.WifiControl.enabled ? Config.Theme.colHighlight : Config.Theme.colMuted

                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: Config.Theme.iconSizeLg
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Wi-Fi"
                        color: Config.Theme.colFg

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSize
                            bold: true
                        }

                    }

                    Text {
                        Layout.fillWidth: true
                        text: Services.WifiControl.enabled ? Services.WifiControl.name : "Disabled"
                        color: Config.Theme.colMuted
                        elide: Text.ElideRight

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeSmall
                        }

                    }

                }

                Text {
                    text: Services.WifiControl.enabled ? (Services.WifiControl.expanded ? "expand_less" : "expand_more") : ""
                    color: Config.Theme.colMuted

                    font {
                        family: "Material Symbols Rounded"
                        pixelSize: Config.Theme.iconSizeMd
                    }

                }

                Rectangle {
                    id: wifiToggle
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 22
                    radius: height / 2
                    color: Services.WifiControl.enabled ? Config.Theme.alpha(Config.Theme.colHighlight, 0.45) : Config.Theme.alpha(Config.Theme.colTextSec, 0.35)

                    Rectangle {
                        x: Services.WifiControl.enabled ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: height / 2
                        color: Services.WifiControl.enabled ? Config.Theme.colHighlight : Config.Theme.colFg
                        Behavior on x { NumberAnimation { duration: 140 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.WifiControl.toggle()
                    }
                }

            }

            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.WifiControl.toggleExpanded()
            }
        }

        // Wi-Fi network list
        ColumnLayout {
            Layout.fillWidth: true
            visible: Services.WifiControl.expanded && Services.WifiControl.enabled
            spacing: Config.Theme.spaceXs
            Repeater {
                model: Services.WifiControl.networks
                delegate: Item {
                    required property var modelData
                    width: 0
                    height: 0

                    Connections {
                        target: modelData
                        function onConnectionFailed(reason) {
                            Services.WifiControl.handleConnectionFailure(modelData, reason);
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Config.Theme.alpha(Config.Theme.colTextSec, 0.2)
            }

            Flickable {
                id: wifiFlickable

                Layout.fillWidth: true
                implicitHeight: Math.min(wifiNetworkColumn.implicitHeight, menu.wifiMaxHeight)
                contentWidth: width
                contentHeight: wifiNetworkColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ScrollBar.vertical: Widgets.ThemeScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Text {
                    anchors.centerIn: parent
                    visible: Services.WifiControl.networks.length === 0
                    text: Services.WifiControl.device?.scannerEnabled ? "Scanning for networks…" : "No networks found"
                    color: Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                }

                Column {
                    id: wifiNetworkColumn

                    width: wifiFlickable.width
                    spacing: Config.Theme.spaceXs
                    Repeater {
                        model: Services.WifiControl.showAll ? Services.WifiControl.networks : Services.WifiControl.networks.slice(0, menu.wifiInitialVisibleCount)

                        delegate: Rectangle {
                            required property var modelData

                            width: wifiNetworkColumn.width
                            height: 42
                            radius: Config.Theme.radiusControl
                            activeFocusOnTab: !modelData.stateChanging
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.name
                                + (modelData.connected ? ", connected" : ", Wi-Fi network")
                            color: activeFocus
                                ? Config.Theme.alpha(Config.Theme.colHighlight, Config.Theme.stateSelectedOpacity)
                                : (wifiNetworkMouse.containsMouse
                                    ? Config.Theme.alpha(Config.Theme.colTextSec, Config.Theme.stateHoverOpacity)
                                    : "transparent")
                            border.width: activeFocus ? 1 : 0
                            border.color: Config.Theme.colHighlight

                            onActiveFocusChanged: {
                                if (activeFocus)
                                    menu.revealNetworkRow(this, wifiFlickable);
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    if (modelData.connected && !modelData.stateChanging)
                                        modelData.disconnect();
                                    else if (!modelData.stateChanging)
                                        Services.WifiControl.connect(modelData);
                                    event.accepted = true;
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: Config.Theme.spaceSm
                                Text {
                                    text: modelData.stateChanging ? "sync"
                                        : (modelData.connected ? "check_circle" : wifiSignalIcon(Math.round((modelData.signalStrength ?? 0) * 100)))
                                    color: modelData.connected ? Config.Theme.colHighlight : Config.Theme.colFg

                                    font {
                                        family: "Material Symbols Rounded"
                                        pixelSize: Config.Theme.iconSizeSm
                                    }

                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Config.Theme.colFg
                                    elide: Text.ElideRight

                                    font {
                                        family: Config.Theme.fontFamily
                                        pixelSize: Config.Theme.fontSizeSmall
                                    }

                                }

                                Text {
                                    text: wifiSecurityIcon(modelData.security)
                                    visible: modelData.security !== WifiSecurityType.Open
                                    color: Config.Theme.colMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Config.Theme.iconSizeXs
                                }

                                Text {
                                    text: Math.round((modelData.signalStrength ?? 0) * 100) + "%"
                                    color: Config.Theme.colMuted
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeCaption
                                }

                                Text {
                                    text: modelData.known ? "Saved" : ""
                                    color: Config.Theme.colMuted
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeCaption
                                }

                            }

                            MouseArea {
                                id: wifiNetworkMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !modelData.stateChanging
                                cursorShape: modelData.stateChanging ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected && !modelData.stateChanging)
                                        modelData.disconnect();
                                    else if (!modelData.stateChanging)
                                        Services.WifiControl.connect(modelData);

                                }
                            }

                        }

                    }

                }

            }

            Widgets.ActionButton {
                Layout.fillWidth: true
                visible: Services.WifiControl.networks.length > menu.wifiInitialVisibleCount
                label: Services.WifiControl.showAll ? "Show less" : "Show all networks"
                iconName: Services.WifiControl.showAll ? "expand_less" : "expand_more"
                Accessible.name: Services.WifiControl.showAll ? "Show fewer Wi-Fi networks" : "Show all Wi-Fi networks"
                onClicked: {
                    Services.WifiControl.showAll = !Services.WifiControl.showAll;
                    if (!Services.WifiControl.showAll)
                        wifiFlickable.contentY = 0;
                }
            }

            Widgets.ActionButton {
                Layout.fillWidth: true
                label: "Refresh networks"
                iconName: "refresh"
                Accessible.name: "Refresh Wi-Fi networks"
                onClicked: Services.WifiControl.refreshNetworks()
            }

            Text {
                Layout.fillWidth: true
                visible: Services.WifiControl.errorText !== ""
                text: Services.WifiControl.errorText
                color: Config.Theme.colRed
                wrapMode: Text.Wrap
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeCaption
            }

            // DNS: a default for every network, plus an exception for the
            // connected one (e.g. a campus Wi-Fi whose login page needs its own DNS).
            ColumnLayout {
                Layout.fillWidth: true
                visible: Services.WifiControl.activeNetwork !== null
                spacing: Config.Theme.spaceSm

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Config.Theme.alpha(Config.Theme.colTextSec, 0.2)
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Config.Theme.spaceXs
                    spacing: Config.Theme.spaceSm

                    Text {
                        text: "dns"
                        color: Config.Theme.colHighlight
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeSm
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "DNS"
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        font.bold: true
                    }

                    Text {
                        visible: Services.DnsControl.busy
                        text: "Applying…"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                    }
                }

                // Login page warning: fixed DNS and no full internet access.
                Rectangle {
                    Layout.fillWidth: true
                    visible: Services.DnsControl.showPortalHint
                    implicitHeight: portalHint.implicitHeight + 2 * Config.Theme.spaceSm
                    radius: Config.Theme.radiusControl
                    color: Config.Theme.alpha(Config.Theme.colYellow, 0.14)

                    ColumnLayout {
                        id: portalHint
                        anchors.fill: parent
                        anchors.margins: Config.Theme.spaceSm
                        spacing: Config.Theme.spaceXs

                        Text {
                            Layout.fillWidth: true
                            text: "No internet access with " + Services.DnsControl.label(Services.DnsControl.activeSpec.mode)
                                + ". If this network has a login page, it may need its own DNS."
                            color: Config.Theme.colFg
                            wrapMode: Text.Wrap
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeCaption
                        }

                        Widgets.LabelButton {
                            Layout.alignment: Qt.AlignRight
                            text: "Use this network's DNS here"
                            labelFontSize: Config.Theme.fontSizeCaption
                            cornerRadius: Config.Theme.radiusSmall
                            outlineOnFocus: true
                            idleTextColor: Config.Theme.colHighlight
                            hoverTextColor: Config.Theme.colHighlight
                            hoverBackgroundColor: Config.Theme.alpha(Config.Theme.colHighlight, 0.14)
                            Accessible.name: "Use the DNS of " + Services.DnsControl.connectionName + " on this network"
                            onClicked: Services.DnsControl.useNetworkDnsHere()
                        }
                    }
                }

                DnsChoice {
                    title: "All networks"
                    currentMode: Config.Preferences.dns.defaultMode
                    currentIpv4: Config.Preferences.dns.defaultIpv4
                    currentIpv6: Config.Preferences.dns.defaultIpv6
                    apply: (mode, ipv4, ipv6) => Services.DnsControl.setDefault(mode, ipv4, ipv6)
                }

                DnsChoice {
                    title: "This network · " + Services.DnsControl.connectionName
                    offerDefault: true
                    defaultLabel: Services.DnsControl.label(Services.DnsControl.defaultSpec.mode)
                    currentMode: Services.DnsControl.networkChoice
                    currentIpv4: Services.DnsControl.activeOverride?.ipv4 ?? ""
                    currentIpv6: Services.DnsControl.activeOverride?.ipv6 ?? ""
                    apply: (mode, ipv4, ipv6) => Services.DnsControl.setNetworkChoice(mode, ipv4, ipv6)
                }

                Text {
                    Layout.fillWidth: true
                    visible: Services.DnsControl.currentServers.length > 0
                    text: "In use: " + Services.DnsControl.currentServers.join(", ")
                    color: Config.Theme.colTextSec
                    wrapMode: Text.Wrap
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeCaption
                }

                Text {
                    Layout.fillWidth: true
                    visible: Services.DnsControl.errorText !== ""
                    text: Services.DnsControl.errorText
                    color: Config.Theme.colRed
                    wrapMode: Text.Wrap
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeCaption
                }
            }

            // Wi-Fi password dialog
            Rectangle {
                Layout.fillWidth: true
                visible: Services.WifiControl.showPassword
                implicitHeight: passwordColumn.implicitHeight + 14
                radius: Config.Theme.radiusControl
                color: Config.Theme.alpha(Config.Theme.colTextSec, 0.1)

                ColumnLayout {
                    id: passwordColumn

                    spacing: 6

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 7
                    }

                    Text {
                        text: "Password for " + Services.WifiControl.pendingSsid
                        color: Config.Theme.colFg

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeCaption
                            bold: true
                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Widgets.ThemedTextField {
                            id: wifiPasswordField

                            Layout.fillWidth: true
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            horizontalTextPadding: 6
                            text: Services.WifiControl.password
                            onTextChanged: Services.WifiControl.password = text
                            Keys.onReturnPressed: Services.WifiControl.connectSecured()

                            font {
                                pixelSize: Config.Theme.fontSizeCaption
                            }

                            background: Rectangle {
                                radius: Config.Theme.radiusSmall
                                color: Config.Theme.alpha(Config.Theme.colTextSec, 0.14)
                                border.width: 1
                                border.color: Config.Theme.alpha(Config.Theme.colTextSec, 0.25)
                            }

                        }

                        Widgets.IconButton {
                            iconName: "arrow_forward"
                            implicitWidth: Config.Theme.controlMinSize
                            implicitHeight: Config.Theme.controlMinSize
                            Accessible.name: "Connect to Wi-Fi network " + Services.WifiControl.pendingSsid
                            onClicked: Services.WifiControl.connectSecured()
                        }

                    }

                    Widgets.LabelButton {
                        Layout.alignment: Qt.AlignLeft
                        text: "Cancel"
                        labelFontSize: Config.Theme.fontSizeCaption
                        cornerRadius: Config.Theme.radiusSmall
                        outlineOnFocus: true
                        idleTextColor: Config.Theme.colMuted
                        hoverTextColor: Config.Theme.colHighlight
                        hoverBackgroundColor: Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
                        Accessible.name: "Cancel Wi-Fi connection"
                        onClicked: Services.WifiControl.cancelPassword()
                    }

                }

            }

        }

    }

}
