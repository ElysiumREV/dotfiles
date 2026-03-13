pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0
    property int maxValue: 1

    readonly property int percentage: Math.round(brightness * 100)

    readonly property string backlightPath: "/sys/class/backlight/amdgpu_bl1/brightness"
    readonly property string maxBrightnessPath: "/sys/class/backlight/amdgpu_bl1/max_brightness"

    Component.onCompleted: {
        maxBrightnessProcess.running = true
    }

    function readBrightness() {
        brightnessReadProcess.running = true
    }

    function setBrightness(value) {
        const clamped = Math.max(0, Math.min(1, value))
        const writeValue = Math.round(clamped * maxValue)

        setBrightnessProcess.command = [
            "/bin/sh",
            "-c",
            "echo " + writeValue + " > " + backlightPath
        ]

        setBrightnessProcess.running = true
        brightness = clamped
    }

    function increaseBrightness() {
        setBrightness(brightness + 0.05)
    }

    function decreaseBrightness() {
        setBrightness(brightness - 0.05)
    }

    Process {
        id: maxBrightnessProcess
        command: ["/bin/cat", maxBrightnessPath]

        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0)
                    maxValue = value
            }
        }

        onExited: {
            brightnessReadProcess.running = true
            updateTimer.running = true
        }
    }

    Process {
        id: brightnessReadProcess
        command: ["/bin/cat", backlightPath]

        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && maxValue > 0)
                    brightness = value / maxValue
            }
        }
    }

    Process {
        id: setBrightnessProcess
        onExited: brightnessReadProcess.running = true
    }

    Timer {
        id: updateTimer
        interval: 100
        repeat: true
        running: false
        onTriggered: brightnessReadProcess.running = true
    }
}
