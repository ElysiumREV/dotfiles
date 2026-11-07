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

    // Prevents an in-flight read from overwriting a change made by the UI.
    property bool settingBrightness: false

    Timer {
        id: settingTimer

        interval: 300
        repeat: false

        onTriggered: {
            root.settingBrightness = false
        }
    }

    Component.onCompleted: {
        detectBacklight()
    }

    function detectBacklight() {
        detectBacklightProcess.running = true
    }

    function readBrightness() {
        if (!supported)
            return

        if (settingBrightness)
            return

        if (brightnessReadProcess.running)
            return

        brightnessReadProcess.running = true
    }

    function setBrightness(value) {
        if (!supported)
            return

        /*
         * Keeps the value always between 0 and 1.
         */
        value = Math.max(
            0,
            Math.min(1, value)
        )

        /*
         * The UI is updated immediately.
         */
        brightness = value

        // Ignores hardware reads started before the user's change.
        settingBrightness = true
        settingTimer.restart()

        // brightnessctl changes the hardware; exec accepts repeated slider updates.
        const valuePercentNumber =
            Math.floor(value * 100)

        /*
         * Avoids leaving the screen completely black.
         */
        const valuePercent =
            valuePercentNumber <= 0
            ? "1"
            : valuePercentNumber + "%"

        setBrightnessProcess.exec([
            "brightnessctl",
            "--class",
            "backlight",
            "s",
            valuePercent,
            "--quiet"
        ])
    }

    function increaseBrightness() {
        setBrightness(
            brightness + 0.05
        )
    }

    function decreaseBrightness() {
        setBrightness(
            brightness - 0.05
        )
    }

    /*
     * Detects the available backlight.
     */
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

                if (!path)
                    return

                root.backlightPath =
                    path + "/brightness"

                root.maxBrightnessPath =
                    path + "/max_brightness"

                console.log(
                    "[Brightness] Using backlight:",
                    path
                )

                root.supported = true

                maxBrightnessProcess.running = true
            }
        }

        onExited: code => {
            if (code !== 0) {
                console.log(
                    "[Brightness] No valid backlight found"
                )

                root.supported = false
            }
        }
    }

    /*
     * Finds the maximum value.
     */
    Process {
        id: maxBrightnessProcess

        command: [
            "cat",
            root.maxBrightnessPath
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value =
                    parseInt(text.trim())

                if (!isNaN(value) && value > 0)
                    root.maxValue = value
            }
        }

        onExited: {
            root.readBrightness()
        }
    }

    /*
     * Reads the current hardware value.
     */
    Process {
        id: brightnessReadProcess

        command: [
            "cat",
            root.backlightPath
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value =
                    parseInt(text.trim())

                if (!isNaN(value) &&
                    root.maxValue > 0 &&
                    !root.settingBrightness) {

                    root.brightness =
                        value / root.maxValue
                }
            }
        }
    }

    /*
     * Process used to change the brightness.
     *
     * IMPORTANT:
     * we use exec() instead of running = true.
     *
     * This lets consecutive calls during the
     * slider drag actually run.
     */
    Process {
        id: setBrightnessProcess
    }

}
