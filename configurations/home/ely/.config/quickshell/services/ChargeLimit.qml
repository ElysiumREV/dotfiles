pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Battery charge limit through UPower (>= 1.90): EnableChargeThreshold on the
// laptop battery. On this Lenovo it maps to the kernel's "Long_Life" charge type
// (conservation mode); laptops with numeric thresholds report them in
// startThreshold/endThreshold. Polkit allows it for the active session without
// a password (org.freedesktop.UPower.enable-charging-limit).
// Read on demand (refresh() when the Battery tab or the battery card opens).
Singleton {
    id: root

    property string devicePath: ""
    property bool supported: false
    property bool enabled: false
    property int startThreshold: 0
    property int endThreshold: 0
    property bool busy: false
    property string errorText: ""

    // Human description of what the limit does on this machine.
    readonly property string description: endThreshold > 0
        ? "Stops charging at " + endThreshold + "%" + (startThreshold > 0 ? " and resumes below " + startThreshold + "%" : "") + "."
        : "The firmware keeps the battery partly charged (conservation mode) to extend its life."

    function refresh() {
        if (!readProcess.running)
            readProcess.exec(["sh", "-c",
                "path=$(upower -e | awk '/\\/battery_[^/]+$/ { print; exit }'); [ -n \"$path\" ] || exit 1; "
                + "echo \"path $path\"; busctl get-property org.freedesktop.UPower \"$path\" org.freedesktop.UPower.Device "
                + "ChargeThresholdSupported ChargeThresholdEnabled ChargeStartThreshold ChargeEndThreshold"]);
    }

    function setEnabled(value) {
        if (!supported || busy || devicePath === "")
            return;
        busy = true;
        errorText = "";
        writeProcess.exec(["busctl", "call", "org.freedesktop.UPower", devicePath,
            "org.freedesktop.UPower.Device", "EnableChargeThreshold", "b", value ? "true" : "false"]);
    }

    Process {
        id: readProcess
        // Output: "path /org/...", then one "<type> <value>" line per property, in order.
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length < 5 || !lines[0].startsWith("path ")) {
                    root.supported = false;
                    return;
                }
                const value = line => line.trim().split(/\s+/)[1] ?? "";
                root.devicePath = lines[0].slice(5).trim();
                root.supported = value(lines[1]) === "true";
                root.enabled = value(lines[2]) === "true";
                root.startThreshold = Number(value(lines[3])) || 0;
                root.endThreshold = Number(value(lines[4])) || 0;
            }
        }
    }

    Process {
        id: writeProcess
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.errorText = text.trim().split("\n").pop();
            }
        }
        onExited: code => {
            root.busy = false;
            if (code === 0)
                root.errorText = "";
            else if (root.errorText === "")
                root.errorText = "UPower did not accept the change.";
            root.refresh();
        }
    }
}
