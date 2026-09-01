pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0
    property int maxValue: 1
    property bool supported: false
    property bool ready: false

    readonly property int percentage: Math.round(brightness * 100)

    property string backlightPath: ""
    property string maxBrightnessPath: ""

    /*
     * Quando true, significa que o valor foi alterado
     * pela UI e não devemos deixar o polling sobrescrevê-lo
     * imediatamente.
     */
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
         * Mantém o valor sempre entre 0 e 1.
         */
        value = Math.max(
            0,
            Math.min(1, value)
        )

        /*
         * A UI é atualizada imediatamente.
         */
        brightness = value

        /*
         * Bloqueia o polling temporariamente.
         */
        settingBrightness = true
        settingTimer.restart()

        /*
         * brightnessctl é responsável pela alteração real.
         *
         * Usamos exec(), como o end-4, porque exec() pode
         * ser chamado repetidamente enquanto o usuário arrasta
         * o slider.
         */
        const valuePercentNumber =
            Math.floor(value * 100)

        /*
         * Evita deixar a tela completamente preta.
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
     * Detecta o backlight disponível.
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
                root.ready = false
            }
        }
    }

    /*
     * Descobre o valor máximo.
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
            root.ready = true
        }
    }

    /*
     * Lê o valor atual do hardware.
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
     * Processo usado para alterar o brilho.
     *
     * IMPORTANTE:
     * usamos exec() em vez de running = true.
     *
     * Isso permite que chamadas consecutivas durante o
     * arrasto do slider sejam realmente executadas.
     */
    Process {
        id: setBrightnessProcess
    }

    /*
     * Mantém o service sincronizado com alterações externas:
     * teclas Fn, brightnessctl, outros programas etc.
     */
    Timer {
        id: pollTimer

        interval: 200
        repeat: true
        running: root.supported

        onTriggered: {
            if (!root.settingBrightness)
                root.readBrightness()
        }
    }
}
