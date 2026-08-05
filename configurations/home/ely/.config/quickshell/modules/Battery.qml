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
    readonly property string iconName: {
        if (isCharging)
            return "battery_charging_full";
        if (batteryLevel <= 5)
            return "battery_0_bar";
        if (batteryLevel <= 20)
            return "battery_1_bar";
        if (batteryLevel <= 35)
            return "battery_2_bar";
        if (batteryLevel <= 50)
            return "battery_3_bar";
        if (batteryLevel <= 65)
            return "battery_4_bar";
        if (batteryLevel <= 80)
            return "battery_5_bar";
        if (batteryLevel <= 95)
            return "battery_6_bar";
        return "battery_full";
    }

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

        Text {
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            text: root.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 20
            color: isPluggedIn ? chargingColor : normalColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
