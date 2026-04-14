import QtQuick
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root

    implicitWidth: row.width
    implicitHeight: row.height

    readonly property var battery: UPower.displayDevice
    readonly property real percentage: battery?.percentage ?? 0
    readonly property int batteryLevel: Math.round(percentage * 100)
    readonly property bool isCharging: battery?.state === UPowerDevice.Charging
    readonly property bool isFullyCharged: battery?.state === UPowerDevice.FullyCharged
    readonly property bool isPluggedIn: isCharging || isFullyCharged
    readonly property bool isLow: batteryLevel <= 25 && !isPluggedIn
    readonly property bool isCritical: batteryLevel <= 15 && !isPluggedIn
    property color colBg: "#13151A"
            property color colFg: "#d4c5b0"
            property color colText: "#F0F1F5"
            property color colTextSec: "#B8BCCA"
            property color colMuted: "#7C8291"
            property color colDisabled: "#505563"
            property color colHighlight: "#A08EC4"
            property color colBlue: "#7EA3CC"
            property color colYellow: "#e6c97a"
            property color colRed: "#C47A7A"
            property color colOrange: "#C4956A"
            property color colGreen: "#7EBD9B"
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 14

    readonly property color normalColor: {
        if (isCritical) return "#c0392b"
        if (isLow)      return "#e6c97a"
        return "#d4c5b0"
    }

    readonly property color chargingColor: "#d4c5b0"

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: batteryLevel + "%"
            font.pixelSize: 12
            font.weight: isLow ? Font.Bold : Font.Normal
            color: isPluggedIn ? chargingColor : normalColor
        }

        Item {
            width: 22
            height: row.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: batteryBody
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 10
                radius: 2
                color: "transparent"
                border.width: 1.5
                border.color: isPluggedIn ? chargingColor : normalColor

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 2.5
                    width: Math.max(0, (parent.width - 5) * root.percentage)
                    radius: 1.5
                    color: isPluggedIn ? chargingColor : normalColor
                }
            }

            Rectangle {
                anchors.left: batteryBody.right
                anchors.leftMargin: -1
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 5
                radius: 1.5
                color: isPluggedIn ? chargingColor : normalColor
            }

            Text {
                visible: isPluggedIn
                anchors.centerIn: batteryBody
                text: ""
                font.family: root.fontFamily
                font.pixelSize: 10
                color: batteryLevel > 50 ? "#181616" : "#c5c9c5"
            }
        }
    }
}
