import QtQuick
import Quickshell
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
    readonly property string icon: volume?.icon ?? "󰕾"

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
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
