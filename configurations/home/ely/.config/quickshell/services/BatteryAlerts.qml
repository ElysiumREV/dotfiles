pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Low battery notifications at 20 %, 10 % and 5 % while discharging. Each level
// warns once per discharge; plugging the charger in re-arms them. Driven by
// UPower property changes (no polling). Started from shell.qml.
Singleton {
    id: root

    readonly property var levels: [20, 10, 5]
    readonly property var battery: UPower.displayDevice
    // Copied by hand in sync() on the device's own change signals: bindings on
    // battery?.state did not re-evaluate when the charger was plugged in or out.
    property bool ready: false
    property int level: 0
    property bool discharging: false
    // Lowest level already announced in this discharge (101 = none yet).
    property int lastWarned: 101

    function formatTime(seconds) {
        const minutes = Math.round(seconds / 60);
        if (!Number.isFinite(minutes) || minutes <= 0)
            return "";
        const hours = Math.floor(minutes / 60);
        return hours > 0 ? hours + " h " + (minutes % 60) + " min" : minutes + " min";
    }

    function check() {
        if (!ready)
            return;
        if (!discharging) {
            lastWarned = 101;
            return;
        }
        // The lowest threshold already crossed; at startup below 10 % this warns
        // once for 10 %, not three times.
        const crossed = levels.filter(threshold => level <= threshold);
        if (crossed.length === 0)
            return;
        const threshold = Math.min.apply(null, crossed);
        if (threshold >= lastWarned)
            return;
        lastWarned = threshold;

        const critical = threshold <= 5;
        const left = formatTime(battery.timeToEmpty ?? 0);
        const body = (left !== "" ? "About " + left + " left. " : "")
            + (critical ? "Plug in the charger now." : "Plug in the charger soon.");
        const args = ["notify-send", "-a", "Battery", "-u", critical ? "critical" : "normal",
            "-i", critical ? "battery-caution" : "battery-low"];
        // The critical warning stays on screen until dismissed.
        if (critical)
            args.push("-t", "0");
        Quickshell.execDetached(args.concat([
            (critical ? "Battery critical: " : "Battery low: ") + level + "%", body]));
    }

    function sync() {
        const b = root.battery;
        ready = !!b && b.ready && b.isPresent;
        if (!ready)
            return;
        level = Math.round(b.percentage * 100);
        discharging = b.state === UPowerDeviceState.Discharging
            || b.state === UPowerDeviceState.PendingDischarge;
        check();
    }

    Connections {
        target: root.battery
        function onStateChanged() { root.sync(); }
        function onPercentageChanged() { root.sync(); }
        function onReadyChanged() { root.sync(); }
        function onIsPresentChanged() { root.sync(); }
    }

    Component.onCompleted: sync()
}
