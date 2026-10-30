import QtQuick
import Quickshell.Services.UPower
import ".." as Config
import "../services/BatteryRules.js" as BatteryRules
import "../widgets" as Widgets

Item {
    id: root

    signal requestMenu()

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery?.isPresent ?? false
    readonly property real percentage: Math.max(0, Math.min(1, battery?.percentage ?? 0))
    readonly property int batteryLevel: Math.round(percentage * 100)
    readonly property bool isCharging: battery?.state === UPowerDevice.Charging
    readonly property bool isFullyCharged: battery?.state === UPowerDevice.FullyCharged
    readonly property bool isPluggedIn: isCharging || isFullyCharged
    readonly property bool isLow: BatteryRules.isLow(batteryLevel, isPluggedIn)
    readonly property bool isCritical: BatteryRules.isCritical(batteryLevel, isPluggedIn)
    property bool groupHighlighted: false
    property bool hovered: false

    implicitWidth: batteryPresent ? batteryIndicatorRow.implicitWidth : 22
    implicitHeight: Config.Theme.moduleHeight
    visible: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: batteryPresent
        ? "Bateria, " + batteryLevel + "%"
            + (isCharging ? ", carregando" : (isFullyCharged ? ", carregada" : ""))
        : "Computador desktop, sem bateria"

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            requestMenu();
            event.accepted = true;
        }
    }

    Row {
        id: batteryIndicatorRow
        visible: root.batteryPresent
        anchors.centerIn: parent
        height: parent.height
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.isCharging && root.batteryLevel < 100
            text: "bolt"
            color: Config.Theme.colFg
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryLevel
            color: Config.Theme.colFg
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
        }

        Widgets.CircularProgressIcon {
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            diameter: 26
            iconSize: 16
            iconName: "battery_android_full"
            progress: root.percentage
            ringColor: root.isCharging ? Config.Theme.colGreen
                : (root.isCritical ? Config.Theme.colBatteryCritical
                   : (root.isLow ? Config.Theme.colYellow : Config.Theme.colHighlight))
            iconColor: root.groupHighlighted
                ? Config.Theme.colOnHighlightContainer : Config.Theme.colFg
        }
    }

    Text {
        visible: !root.batteryPresent
        anchors.centerIn: parent
        text: "computer"
        color: root.groupHighlighted ? Config.Theme.colOnHighlightContainer : Config.Theme.colMuted
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.batteryPresent ? batteryIndicatorRow.implicitWidth + 8 : 25
        height: root.batteryPresent ? 30 : 25
        radius: height / 2
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Config.Theme.colHighlight
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
