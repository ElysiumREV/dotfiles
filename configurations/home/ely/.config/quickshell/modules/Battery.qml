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

    readonly property color normalColor: {
    if (isCritical)
        return "#f7768e"
    if (isLow)
        return "#e0af68"
    return "#c0caf5"
}

readonly property color chargingColor: "#7dcfff"


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
                text: "⚡"
                font.pixelSize: 9
                color: batteryLevel > 50 ? "#000000" : "#ffffff"
            }
        }
    }
}
