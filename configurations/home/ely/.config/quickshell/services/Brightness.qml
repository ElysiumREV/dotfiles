pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0
    property int maxValue: 1
    property bool supported: false

    readonly property int percentage: Math.round(brightness * 100)

    property string backlightPath: ""
    property string maxBrightnessPath: ""

    Component.onCompleted: {
        detectBacklight()
    }

    function detectBacklight() {
        detectBacklightProcess.running = true
    }

    function readBrightness() {
        if (!supported) return
        brightnessReadProcess.running = true
    }

    function setBrightness(value) {
        if (!supported) return

        const clamped = Math.max(0, Math.min(1, value))
        const writeValue = Math.round(clamped * maxValue)

        setBrightnessProcess.command = [
            "sh",
            "-c",
            "echo " + writeValue + " | tee " + backlightPath + " >/dev/null"
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
        id: detectBacklightProcess
        command: [
            "sh",
            "-c",
            "for name in amdgpu_bl1 amdgpu_bl0 intel_backlight acpi_video0; do path=/sys/class/backlight/$name; if [ -d \"$path\" ]; then printf '%s\\n' \"$path\"; exit 0; fi; done; exit 1"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (!path) return

                backlightPath = path + "/brightness"
                maxBrightnessPath = path + "/max_brightness"

                console.log("[Brightness] Using backlight:", path)

                supported = true
                maxBrightnessProcess.running = true
            }
        }

        onExited: code => {
            if (code !== 0) {
                console.log("[Brightness] No valid backlight found")
                supported = false
            }
        }
    }

    Process {
        id: maxBrightnessProcess
        command: ["cat", maxBrightnessPath]

        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0) {
                    maxValue = value
                }
            }
        }

        onExited: {
            brightnessReadProcess.running = true
        }
    }

    Process {
        id: brightnessReadProcess
        command: ["cat", backlightPath]

        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && maxValue > 0) {
                    brightness = value / maxValue
                }
            }
        }
    }

    Process {
        id: setBrightnessProcess

        onExited: {
            brightnessReadProcess.running = true
        }
    }

    Timer {
        id: pollTimer
        interval: 200
        repeat: true
        running: supported
        onTriggered: brightnessReadProcess.running = true
    }
}
