import "../.." as Config
import "../../services" as Services
import "../../widgets" as Widgets
import QtQuick
import QtQuick.Layouts

// DNS settings: a default for every network, plus an exception for the main
// connection (Wi-Fi or wired), e.g. a campus Wi-Fi whose login page needs its
// own DNS. Shown in the Wi-Fi panel and in the Settings tab.
ColumnLayout {
    id: dnsSection

    // false hides the divider line at the top (when it opens a page/card itself).
    property bool showDivider: true

    Layout.fillWidth: true
    visible: Services.DnsControl.activeUuid !== ""
    spacing: Config.Theme.spaceSm

    Rectangle {
        Layout.fillWidth: true
        visible: dnsSection.showDivider
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
            + (Services.DnsControl.connectionType === "wired" ? " (wired)" : "")
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
