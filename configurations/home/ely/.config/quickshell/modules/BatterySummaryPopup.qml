import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import ".." as Config
import "../services" as Services

// Hover card under the bar battery: state, time left, power draw, health and
// power profile. Everything comes from UPower properties the shell already
// tracks, so showing it starts no process or timer.
PopupWindow {
    id: root

    required property Item anchorItem
    required property var battery
    required property bool isCharging
    required property bool isFullyCharged
    required property color levelColor

    readonly property var laptopBattery: UPower.devices.values.find(device => device.isLaptopBattery) ?? null
    readonly property int level: Math.round(Math.max(0, Math.min(1, battery?.percentage ?? 0)) * 100)
    readonly property bool isDischarging: battery?.state === UPowerDeviceState.Discharging
        || battery?.state === UPowerDeviceState.PendingDischarge
    readonly property real watts: Math.abs(Number(battery?.changeRate ?? 0))
    readonly property real secondsLeft: isCharging ? Number(battery?.timeToFull ?? 0)
        : (isDischarging ? Number(battery?.timeToEmpty ?? 0) : 0)

    readonly property string stateText: isFullyCharged ? "Fully charged"
        : isCharging ? "Charging"
        : isDischarging ? "On battery"
        : "Plugged in"
    readonly property string timeText: {
        const duration = formatDuration(secondsLeft);
        if (duration === "")
            return isDischarging || isCharging ? "Estimating time…" : "";
        return isCharging ? duration + " until full" : duration + " left";
    }

    function formatDuration(seconds) {
        const minutes = Math.round(seconds / 60);
        if (!Number.isFinite(minutes) || minutes <= 0)
            return "";
        const hours = Math.floor(minutes / 60);
        return hours > 0 ? hours + " h " + (minutes % 60) + " min" : minutes + " min";
    }

    component InfoRow: RowLayout {
        id: infoRow
        required property string icon
        required property string label
        Layout.fillWidth: true
        spacing: Config.Theme.spaceSm
        visible: label !== ""

        Text {
            text: infoRow.icon
            color: Config.Theme.colHighlight
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.Theme.iconSizeXs
        }

        Text {
            Layout.fillWidth: true
            text: infoRow.label
            color: Config.Theme.colFg
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }

    anchor.item: anchorItem
    anchor.rect.x: anchorItem.width / 2
    anchor.rect.y: anchorItem.height
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: 248
    implicitHeight: content.implicitHeight + 2 * Config.Theme.spaceMd
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Config.Theme.radiusCard
        color: Config.Theme.colSurfaceRaised
        border.width: 1
        border.color: Config.Theme.colBorderSubtle
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Config.Theme.spaceMd
        spacing: Config.Theme.spaceSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceSm

            Text {
                text: root.isCharging ? "battery_charging_full" : "battery_android_full"
                color: root.levelColor
                font.family: "Material Symbols Rounded"
                font.pixelSize: Config.Theme.iconSizeXl
            }

            Text {
                text: root.level + "%"
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeLarge
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: root.stateText
                color: Config.Theme.colTextSec
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }

        // Charge bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Config.Theme.alpha(Config.Theme.colTextSec, 0.18)

            Rectangle {
                width: parent.width * root.level / 100
                height: parent.height
                radius: parent.radius
                color: root.levelColor
            }
        }

        InfoRow {
            icon: "schedule"
            label: root.timeText
        }

        InfoRow {
            icon: "bolt"
            label: root.watts >= 0.1
                ? (root.isCharging ? "Charging at " : "Using ") + root.watts.toFixed(1) + " W"
                : ""
        }

        InfoRow {
            icon: "health_and_safety"
            label: root.laptopBattery?.healthSupported
                ? "Health " + Math.round(root.laptopBattery.healthPercentage) + "%"
                : ""
        }

        InfoRow {
            icon: Services.PowerProfiles.getProfileIcon(Services.PowerProfiles.activeProfile)
            label: Services.PowerProfiles.getProfileLabel(Services.PowerProfiles.activeProfile) + " profile"
        }

        Text {
            Layout.fillWidth: true
            text: "Click for details"
            color: Config.Theme.colMuted
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeCaption
        }
    }
}
