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
    var basePath = "/sys/class/backlight"

    var candidates = [
        "amdgpu_bl1",
        "amdgpu_bl0",
        "intel_backlight",
        "acpi_video0"
    ]

    for (var i = 0; i < candidates.length; i++) {
        var path = basePath + "/" + candidates[i]

        // IMPORTANT: only accept real sysfs directories
        if (!Qt.resolvedUrl(path)) continue

        backlightPath = path + "/brightness"
        maxBrightnessPath = path + "/max_brightness"

        console.log("[Brightness] Using backlight:", path)

        supported = true
        maxBrightnessProcess.running = true
        return
    }

    console.log("[Brightness] No valid backlight found")
    supported = false
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