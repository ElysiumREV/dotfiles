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
        var possiblePaths = [
            basePath + "/amdgpu_bl1",
            basePath + "/amdgpu_bl0",
            basePath + "/intel_backlight",
            basePath + "/acpi_video0",
            basePath + "/acpi_video1",
            basePath + "/radeon_bl0",
            basePath + "/nvidia_0"
        ]

        for (var i = 0; i < possiblePaths.length; i++) {
            var path = possiblePaths[i]
            var comp = Qt.createComponent(path + "/brightness")
            if (comp !== null) {
                backlightPath = path + "/brightness"
                maxBrightnessPath = path + "/max_brightness"
                supported = true
                console.log("[Brightness] Found backlight at:", path)
                maxBrightnessProcess.running = true
                return
            }
        }

        supported = false
        console.log("[Brightness] No backlight device found")
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
