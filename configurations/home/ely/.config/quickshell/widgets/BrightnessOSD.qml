import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".." as Config
import "." as QsWidgets
import "../services" as QsServices

Scope {
    id: root

    readonly property var brightness: QsServices.Brightness
    readonly property int percentage: brightness?.percentage ?? 0

    property bool shouldShowOsd: false
    property int lastPercentage: percentage
    property bool startupComplete: false

    Timer {
        id: startupTimer
        interval: 2000
        running: true
        onTriggered: root.startupComplete = true
    }

    readonly property string icon: {
        if (percentage >= 66) return "brightness_high"
        if (percentage >= 33) return "brightness_medium"
        return "brightness_low"
    }

    onPercentageChanged: {
        if (!startupComplete) return;
        if (percentage !== lastPercentage) {
            root.shouldShowOsd = true;
            hideTimer.restart();
            lastPercentage = percentage;
        }
    }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    readonly property var focusedScreen: Quickshell.screens.find(
        screen => Hyprland.monitorFor(screen) === Hyprland.focusedMonitor
    ) ?? Quickshell.screens[0] ?? null

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            // Shown on the monitor that has focus, like the notification popups.
            screen: root.focusedScreen
            anchors.bottom: true
            margins.bottom: screen.height / 5
            exclusiveZone: 0

            implicitHeight: Config.Theme.osdHeight
            implicitWidth: Config.Theme.osdWidth
            color: "transparent"

            mask: Region {}

            QsWidgets.OsdCard {
                anchors.fill: parent
                title: "Brightness"
                iconName: root.icon
                value: root.percentage + "%"
                progress: root.percentage / 100
            }
        }
    }
}
