pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".." as Config

// Screen color temperature (night light) and gamma through hyprsunset's IPC
// (`hyprctl hyprsunset temperature|gamma`). On a desktop monitor without a
// backlight, gamma is the only way to dim the screen from the shell.
// The choices live in settings.json (display.*) and are re-applied at startup,
// since hyprsunset itself starts neutral.
Singleton {
    id: root

    readonly property int neutralTemperature: 6000 // hyprsunset's identity
    readonly property int minTemperature: 2500
    readonly property int minGamma: 20 // lower than this is close to a black screen

    readonly property var prefs: Config.Preferences.display
    readonly property bool nightLight: prefs.nightLight
    readonly property int temperature: prefs.temperature
    readonly property int gamma: prefs.gamma

    // false until hyprsunset answered once (it may start after the shell at login).
    property bool available: false
    property string errorText: ""
    property int retries: 0

    function setNightLight(enabled) {
        prefs.nightLight = enabled;
        scheduleApply();
    }

    function setTemperature(kelvin) {
        prefs.temperature = Math.round(Math.max(minTemperature, Math.min(neutralTemperature, kelvin)) / 100) * 100;
        if (!prefs.nightLight)
            prefs.nightLight = true; // moving the warmth slider means "use night light"
        scheduleApply();
    }

    function setGamma(percent) {
        prefs.gamma = Math.round(Math.max(minGamma, Math.min(100, percent)));
        scheduleApply();
    }

    function toggleNightLight() {
        setNightLight(!prefs.nightLight);
    }

    // Slider drags change the value many times per second; send only the latest.
    function scheduleApply() {
        applyDelay.restart();
    }

    function apply() {
        if (applyProcess.running) {
            applyDelay.restart();
            return;
        }
        const kelvin = prefs.nightLight ? prefs.temperature : neutralTemperature;
        applyProcess.exec(["sh", "-c",
            'hyprctl hyprsunset temperature "$1" && hyprctl hyprsunset gamma "$2"',
            "hyprsunset", String(kelvin), String(prefs.gamma)]);
    }

    Timer {
        id: applyDelay
        interval: 120
        repeat: false
        onTriggered: root.apply()
    }

    // At startup hyprsunset may not be up yet: retry for about half a minute.
    Timer {
        id: retryTimer
        interval: 3000
        repeat: false
        onTriggered: root.apply()
    }

    Connections {
        target: Config.Preferences
        function onLoadedChanged() {
            if (Config.Preferences.loaded)
                root.apply();
        }
    }

    Component.onCompleted: {
        if (Config.Preferences.loaded)
            apply();
    }

    Process {
        id: applyProcess
        // hyprctl prints "ok" per command (its exit code is 0 even when
        // hyprsunset is not running), so success is judged from the output.
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").map(line => line.trim()).filter(Boolean);
                const ok = lines.length >= 2 && lines.every(line => line === "ok");
                if (ok) {
                    root.available = true;
                    root.retries = 0;
                    root.errorText = "";
                } else if (!root.available && root.retries < 10) {
                    root.retries++;
                    retryTimer.restart();
                } else {
                    root.errorText = lines.find(line => line !== "ok") || "hyprsunset is not responding.";
                }
            }
        }
    }
}
