pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var pipewire: Pipewire

    PwObjectTracker {
        objects: [root.pipewire.defaultAudioSink]
    }

    property var audioIface: null
    property real volume: 0
    property bool muted: false
    property int percentage: 0
    property string icon: "󰕾"

    Component.onCompleted: bindDefaultSink()

    function bindDefaultSink() {
        const nextAudioIface = pipewire.defaultAudioSink?.audio ?? null
        if (audioIface !== nextAudioIface) {
            audioIface = nextAudioIface
            if (audioIface) {
                updateProperties()
            } else {
                volume = 0
                percentage = 0
                muted = false
                icon = "󰕾"
            }
        }

        if (!audioIface) {
            sinkTimer.start()
        } else {
            sinkTimer.stop()
        }
    }

    Connections {
        target: root.pipewire

        function onDefaultAudioSinkChanged() {
            root.bindDefaultSink()
        }
    }

    Connections {
        target: root.audioIface

        function onVolumeChanged() {
            root.updateProperties()
        }

        function onMutedChanged() {
            root.updateProperties()
        }
    }

    function updateProperties() {
        if (audioIface) {
            volume = audioIface.volume ?? 0
            muted = audioIface.muted ?? false
            percentage = Math.round(volume * 100)

            if (muted) icon = "󰝟"
            else if (percentage >= 66) icon = "󰕾"
            else if (percentage >= 33) icon = "󰖀"
            else if (percentage > 0) icon = "󰕿"
            else icon = "󰝟"
        }
    }

    Timer {
        id: sinkTimer
        interval: 2000
        repeat: false
        onTriggered: root.bindDefaultSink()
    }

    function setVolume(value) {
        if (audioIface) {
            audioIface.volume = Math.max(0, Math.min(1, value))
            updateProperties()
        }
    }

    function increaseVolume(step = 0.05) {
        setVolume(volume + step)
    }

    function decreaseVolume(step = 0.05) {
        setVolume(volume - step)
    }

    function toggleMute() {
        if (audioIface) {
            audioIface.muted = !audioIface.muted
            updateProperties()
        }
    }
}
