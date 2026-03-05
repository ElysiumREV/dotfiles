pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var pipewire: Pipewire

    property var audioIface: null
    property real volume: 0
    property bool muted: false
    property int percentage: 0
    property string icon: "󰕾"

    Component.onCompleted: checkForSink()

    function checkForSink() {
        if (pipewire.defaultAudioSink?.audio) {
            audioIface = pipewire.defaultAudioSink.audio
            updateProperties()
            pollTimer.start()
        } else {
            sinkTimer.start()
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
        interval: 500
        repeat: false
        onTriggered: root.checkForSink()
    }

    Timer {
        id: pollTimer
        interval: 100
        repeat: true
        running: root.audioIface !== null
        onTriggered: root.updateProperties()
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
