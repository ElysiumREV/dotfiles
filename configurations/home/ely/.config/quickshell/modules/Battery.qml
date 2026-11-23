import QtQuick
import Quickshell
import Quickshell.Services.UPower
import ".." as Config
import "../services" as Services
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
    readonly property color levelColor: isCharging ? Config.Theme.colGreen
        : (isCritical ? Config.Theme.colBatteryCritical
           : (isLow ? Config.Theme.colYellow : Config.Theme.colHighlight))

    // Hover/focus summary card. A click opens the full panel, so it hides the
    // card until the pointer leaves.
    property bool summarySuppressed: false
    readonly property bool summaryWanted: batteryPresent && !summarySuppressed
        && (batteryMouse.containsMouse || activeFocus)
    onSummaryWantedChanged: {
        if (summaryWanted)
            summaryDelay.restart();
        else {
            summaryDelay.stop();
            summaryLoader.active = false;
        }
    }

    Timer {
        id: summaryDelay
        interval: 400
        onTriggered: {
            Services.ChargeLimit.refresh();
            summaryLoader.active = root.summaryWanted;
        }
    }

    LazyLoader {
        id: summaryLoader

        BatterySummaryPopup {
            anchorItem: root
            battery: root.battery
            isCharging: root.isCharging
            isFullyCharged: root.isFullyCharged
            levelColor: root.levelColor
            visible: true
        }
    }

    implicitWidth: batteryPresent ? batteryIndicatorRow.implicitWidth : 22
    implicitHeight: Config.Theme.moduleHeight
    visible: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: batteryPresent
        ? "Battery, " + batteryLevel + "%"
            + (isCharging ? ", charging" : (isFullyCharged ? ", fully charged" : ""))
        : "Desktop computer, no battery"

    onActiveFocusChanged: if (!activeFocus) summarySuppressed = false
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            summarySuppressed = true;
            requestMenu();
            event.accepted = true;
        }
    }

    Row {
        id: batteryIndicatorRow
        visible: root.batteryPresent
        anchors.centerIn: parent
        height: parent.height
        spacing: Config.Theme.spaceXs
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryLevel
            color: root.groupHighlighted ? Config.Theme.colOnHighlightContainer : Config.Theme.colFg
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
        }

        Widgets.CircularProgressIcon {
            width: 26
            height: 26
            anchors.verticalCenter: parent.verticalCenter
            diameter: 26
            iconSize: Config.Theme.iconSizeXs
            // Charging is shown inside the ring (and by its green color), so the
            // row width never changes and there is no gap when unplugged.
            iconName: root.isCharging && root.batteryLevel < 100 ? "bolt" : "battery_android_full"
            progress: root.percentage
            ringColor: root.levelColor
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
        font.pixelSize: Config.Theme.iconSizeSm
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
        id: batteryMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onExited: root.summarySuppressed = false
        onClicked: {
            root.summarySuppressed = true;
            root.requestMenu();
        }
    }
}
