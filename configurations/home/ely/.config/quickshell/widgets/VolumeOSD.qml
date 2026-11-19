import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".." as Config
import "." as QsWidgets
import "../services" as QsServices

Scope {
    id: root

    Connections {
        target: root.volume || null

        function onVolumeChanged() {
            root.showOsd()
        }

        function onMutedChanged() {
            root.showOsd()
        }
    }

    function showOsd() {
        if (!startupComplete) return
        shouldShowOsd = true
        hideTimer.restart()
    }

    property bool shouldShowOsd: false
    property bool startupComplete: false

    Timer {
        id: startupTimer
        interval: 2000
        running: true
        onTriggered: root.startupComplete = true
    }

    readonly property var volume: QsServices.Volume
    readonly property int percentage: volume?.percentage ?? 0
    readonly property bool muted: volume?.effectivelyMuted ?? true
    // Same Material Symbols names as the bar volume module.
    readonly property string icon: muted || percentage <= 0 ? "volume_off"
        : (percentage < 35 ? "volume_down" : "volume_up")

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
                title: "Volume"
                iconName: root.icon
                value: root.muted ? "Muted" : root.percentage + "%"
                progress: root.percentage / 100
                muted: root.muted
            }
        }
    }
}
