import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".." as Config

Item {
    id: root

    implicitWidth: row.width
    implicitHeight: Config.Theme.moduleHeight

    readonly property var battery: UPower.displayDevice
    readonly property real percentage: battery?.percentage ?? 0
    readonly property int batteryLevel: Math.round(percentage * 100)
    readonly property bool isCharging: battery?.state === UPowerDevice.Charging
    readonly property bool isFullyCharged: battery?.state === UPowerDevice.FullyCharged
    readonly property bool isPluggedIn: isCharging || isFullyCharged
    readonly property bool isLow: batteryLevel <= 25 && !isPluggedIn
    readonly property bool isCritical: batteryLevel <= 20 && !isPluggedIn

    readonly property color normalColor: {
        if (isCritical) return Config.Theme.colBatteryCritical
        if (isLow)      return Config.Theme.colYellow
        return Config.Theme.colFg
    }

    readonly property color chargingColor: Config.Theme.colFg

    Row {
        id: row
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleInnerSpacing

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: batteryLevel + "%"
            font.pixelSize: Config.Theme.batteryTextSize
            font.weight: isLow ? Font.Bold : Font.Normal
            color: isPluggedIn ? chargingColor : normalColor
        }

        Item {
            width: Config.Theme.batteryShellWidth
            height: Config.Theme.batteryShellHeight
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: batteryBody
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Config.Theme.batteryBodyWidth
                height: Config.Theme.batteryBodyHeight
                radius: Config.Theme.batteryBodyRadius
                color: "transparent"
                border.width: Config.Theme.batteryBorderWidth
                border.color: isPluggedIn ? chargingColor : normalColor

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: Config.Theme.batteryFillMargin
                    width: Math.max(0, (parent.width - Config.Theme.batteryFillMargin * 2) * root.percentage)
                    radius: Config.Theme.batteryFillRadius
                    color: isPluggedIn ? chargingColor : normalColor
                }
            }

            Rectangle {
                anchors.left: batteryBody.right
                anchors.leftMargin: Config.Theme.batteryTipOverlap
                anchors.verticalCenter: parent.verticalCenter
                width: Config.Theme.batteryTipWidth
                height: Config.Theme.batteryTipHeight
                radius: Config.Theme.batteryTipRadius
                color: isPluggedIn ? chargingColor : normalColor
            }

            Text {
                visible: isPluggedIn
                anchors.centerIn: batteryBody
                text: ""
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.batteryIconSize
                color: batteryLevel > 50 ? Config.Theme.colBatteryIconDark : Config.Theme.colBatteryIconLight
            }
        }
    }
}
