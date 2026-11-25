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
Singleton {
    id: root

    readonly property int lowLevel: 25
    // The battery has to climb back above this before 25 % triggers again,
    // so a reading bouncing around 25 % doesn't override a manual choice.
    readonly property int rearmLevel: 30

    readonly property var battery: UPowerService.UPower.displayDevice
    readonly property bool ready: (battery?.ready ?? false) && (battery?.isPresent ?? false)
    readonly property int level: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool onBattery: UPowerService.UPower.onBattery

    property bool started: false
    property bool lowApplied: false

    function target() {
        if (!onBattery)
            return PowerProfiles.availableProfiles.includes("performance") ? "performance" : "balanced";
        return level <= lowLevel ? "power-saver" : "balanced";
    }

    function apply() {
        lowApplied = onBattery && level <= lowLevel;
        PowerProfiles.setProfile(target());
    }

    function levelChanged_() {
        if (!started || !onBattery)
            return;
        if (level > rearmLevel) {
            lowApplied = false;
        } else if (level <= lowLevel && !lowApplied) {
            lowApplied = true;
            PowerProfiles.setProfile("power-saver");
        }
    }

    onReadyChanged: {
        if (ready && !started) {
            started = true;
            apply();
        }
    }
    onOnBatteryChanged: {
        if (started)
            apply();
    }
    onLevelChanged: levelChanged_()

    Component.onCompleted: {
        if (ready && !started) {
            started = true;
            apply();
        }
    }
}
