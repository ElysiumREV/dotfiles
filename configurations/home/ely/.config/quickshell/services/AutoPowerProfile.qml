pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower as UPowerService

// Picks the power profile on its own (laptop only):
//   charger plugged in            -> performance (balanced if there is none)
//   on battery, above 25 %        -> balanced
//   on battery, 25 % or below     -> power-saver
// It acts only on events: shell start (so a profile left over from before a
// shutdown is corrected), charger plugged/unplugged, and the battery falling
// to 25 %. A profile picked by hand therefore stays until the next event.
// Started from shell.qml.
//
// The battery values are copied by hand in sync() on the device's own change
// signals: bindings on battery?.state did not re-evaluate when the charger
// was plugged in or out, which a log of the raw signals showed.
Singleton {
    id: root

    readonly property int lowLevel: 25
    // The battery has to climb back above this before 25 % triggers again,
    // so a reading bouncing around 25 % doesn't override a manual choice.
    readonly property int rearmLevel: 30

    readonly property var battery: UPowerService.UPower.displayDevice

    property bool ready: false
    property int level: 0
    property bool unplugged: false
    property bool started: false
    property bool lowApplied: false

    function target() {
        if (!unplugged)
            return PowerProfiles.availableProfiles.includes("performance") ? "performance" : "balanced";
        return level <= lowLevel ? "power-saver" : "balanced";
    }

    function apply() {
        lowApplied = unplugged && level <= lowLevel;
        PowerProfiles.setProfile(target());
    }

    function sync() {
        const b = root.battery;
        ready = !!b && b.ready && b.isPresent;
        if (!ready)
            return;

        const wasUnplugged = unplugged;
        const wasLevel = level;
        level = Math.round(b.percentage * 100);
        unplugged = b.state === UPowerService.UPowerDeviceState.Discharging
            || b.state === UPowerService.UPowerDeviceState.PendingDischarge;

        if (!started) {
            started = true;
            apply();
        } else if (unplugged !== wasUnplugged) {
            apply();
        } else if (unplugged && level !== wasLevel) {
            if (level > rearmLevel) {
                lowApplied = false;
            } else if (level <= lowLevel && !lowApplied) {
                lowApplied = true;
                PowerProfiles.setProfile("power-saver");
            }
        }
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
