import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".." as Config
import "../services/BatteryRules.js" as BatteryRules

Item {
    id: root

    signal requestMenu()

    implicitWidth: row.width
    implicitHeight: Config.Theme.moduleHeight

    property bool hovered: false

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery?.isPresent ?? false
    readonly property real percentage: battery?.percentage ?? 0
    readonly property int batteryLevel: Math.round(percentage * 100)
    readonly property bool isCharging: battery?.state === UPowerDevice.Charging
    readonly property bool isFullyCharged: battery?.state === UPowerDevice.FullyCharged
    readonly property bool isPluggedIn: isCharging || isFullyCharged
    readonly property bool isLow: BatteryRules.isLow(batteryLevel, isPluggedIn)
    readonly property bool isCritical: BatteryRules.isCritical(batteryLevel, isPluggedIn)

    readonly property string iconName: batteryPresent
        ? BatteryRules.iconName(batteryLevel, isCharging)
        : "desktop_windows"

    readonly property color normalColor: {
        if (!batteryPresent)
            return Config.Theme.colMuted;
        if (isCritical)
            return Config.Theme.colBatteryCritical;
        if (isLow)
            return Config.Theme.colYellow;
        return Config.Theme.colFg;
    }

    readonly property color chargingColor: Config.Theme.colFg

    readonly property color moduleColor: {
        if (hovered)
            return Config.Theme.colHighlight;

        if (isCharging || isFullyCharged)
            return chargingColor;

        return normalColor;
    }

    Row {
        id: row

        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleInnerSpacing

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: batteryLevel + "%"
            visible: root.batteryPresent

            font.pixelSize: Config.Theme.batteryTextSize
            font.weight: isLow ? Font.Bold : Font.Normal

            color: root.moduleColor
        }

        Text {
            width: 20
            height: 20

            anchors.verticalCenter: parent.verticalCenter

            text: root.iconName

            font.family: "Material Symbols Rounded"
            font.pixelSize: 20

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            color: root.moduleColor
        }
    }

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: root.hovered = false

        onClicked: root.requestMenu()
    }
}
