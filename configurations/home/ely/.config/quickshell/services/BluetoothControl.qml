pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// State and operations behind the Bluetooth section of the Arch Menu.
// Devices, connections and pairing go through the native Quickshell/BlueZ API,
// which updates by events (no polling). bluetoothctl is only used by
// BluetoothPairingAgent to answer PIN/confirmation requests.
Singleton {
    id: root

    // Set by the Arch Menu while it is visible; gates agent cleanup.
    property bool menuVisible: false
    property bool expanded: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    // While rfkill soft-blocks the radio BlueZ may expose no adapter at all; treat
    // that as blocked too so the power button still tries to unblock it.
    readonly property bool blocked: !adapter || adapter.state === BluetoothAdapterState.Blocked
    // Set when the adapter must be powered on as soon as rfkill releases it.
    property bool enableWhenReady: false
    readonly property bool scanning: adapter?.discovering ?? false
    readonly property int connectedCount: Bluetooth.devices.values.filter(device => device.connected).length

    // BluetoothDevice objects: connected first, then paired, then named, then by name.
    readonly property var devices: {
        if (!enabled)
            return [];
        const list = (adapter?.devices?.values ?? []).slice();
        list.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            const aNamed = hasName(a);
            const bNamed = hasName(b);
            if (aNamed !== bNamed)
                return aNamed ? -1 : 1;
            return displayName(a).localeCompare(displayName(b), undefined, { sensitivity: "base" });
        });
        return list;
    }

    property string actionMessage: ""
    property string busyAddress: ""
    property string busyAction: ""
    property var busyDevice: null
    // True once BlueZ reported the operation in progress, so a later idle state means failure.
    property bool busyStarted: false
    property string pendingForgetAddress: ""

    // A forgotten device usually disappears from the list instead of changing state.
    onDevicesChanged: {
        if (busyAction === "forget" && !deviceFor(busyAddress))
            finishAction("");
    }

    onEnabledChanged: {
        if (!enabled) {
            expanded = false;
            scanTimer.stop();
            finishAction("");
            BluetoothPairingAgent.release();
        } else if (expanded) {
            BluetoothPairingAgent.ensureStarted();
        }
    }

    function hasName(device) {
        const name = device?.name ?? "";
        return name !== "" && !/^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$/i.test(name);
    }

    function displayName(device) {
        return device?.name || device?.deviceName || device?.address || "Unknown device";
    }

    function deviceFor(address) {
        return (adapter?.devices?.values ?? []).find(device => device.address === address) ?? null;
    }

    // Releases the pairing agent unless a pairing is still in progress.
    function releaseAgentIfIdle() {
        if (busyAction !== "pair" && BluetoothPairingAgent.promptType === "")
            BluetoothPairingAgent.release();
    }

    function cleanup() {
        stopScan();
        releaseAgentIfIdle();
    }

    onAdapterChanged: {
        if (adapter && enableWhenReady) {
            enableWhenReady = false;
            adapter.enabled = true;
        }
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true
        function onStateChanged() {
            if (root.enableWhenReady && root.adapter.state !== BluetoothAdapterState.Blocked) {
                root.enableWhenReady = false;
                root.adapter.enabled = true;
            }
        }
    }

    function toggle() {
        if (enabled) {
            expanded = false;
            stopScan();
        } else if (blocked) {
            actionMessage = "";
            unblockProcess.running = true;
            return;
        }
        if (adapter)
            adapter.enabled = !enabled;
    }

    function toggleDetails() {
        setExpanded(!expanded);
    }

    function toggleExpanded() {
        if (expanded)
            setExpanded(false);
        else if (enabled)
            setExpanded(true);
    }

    function setExpanded(value) {
        if (expanded === value)
            return;

        expanded = value;
        if (value) {
            WifiControl.expanded = false;
            if (!enabled)
                return;
            BluetoothPairingAgent.ensureStarted();
            startScan();
        } else {
            stopScan();
            releaseAgentIfIdle();
        }
    }

    function beginAction(action, device, timeoutMs) {
        actionMessage = "";
        busyDevice = device;
        busyAddress = device.address;
        busyAction = action;
        busyStarted = false;
        actionTimeout.interval = timeoutMs;
        actionTimeout.restart();
    }

    // message === "" means success (or nothing to report).
    function finishAction(message) {
        actionTimeout.stop();
        busyDevice = null;
        busyAddress = "";
        busyAction = "";
        busyStarted = false;
        actionMessage = message;
        if (!menuVisible)
            releaseAgentIfIdle();
    }

    function failureMessage(action) {
        return action === "pair" ? "Could not pair. Check that the device is in pairing mode."
            : action === "connect" ? "Could not connect to the device."
            : action === "disconnect" ? "Could not disconnect the device."
            : "Could not remove the paired device.";
    }

    function connectDevice(address) {
        const device = deviceFor(address);
        if (busyAction !== "" || !device)
            return;
        beginAction("connect", device, 20000);
        device.connect();
    }

    function disconnectDevice(address) {
        const device = deviceFor(address);
        if (busyAction !== "" || !device)
            return;
        beginAction("disconnect", device, 10000);
        device.disconnect();
    }

    function pairDevice(address) {
        const device = deviceFor(address);
        if (busyAction !== "" || !device)
            return;
        beginAction("pair", device, 60000);
        BluetoothPairingAgent.ensureStarted();
        // Give the agent a moment to register before BlueZ asks it anything.
        pairStartTimer.restart();
    }

    function forgetDevice(address) {
        if (busyAction !== "")
            return;
        pendingForgetAddress = address;
    }

    function confirmForget() {
        const device = deviceFor(pendingForgetAddress);
        pendingForgetAddress = "";
        if (!device)
            return;
        beginAction("forget", device, 5000);
        device.forget();
    }

    function deviceName(address) {
        const device = deviceFor(address);
        return device ? displayName(device) : address;
    }

    function startScan() {
        if (!enabled || !adapter)
            return;
        adapter.discovering = true;
        scanTimer.restart();
    }

    function stopScan() {
        scanTimer.stop();
        if (adapter)
            adapter.discovering = false;
    }

    function isConnected(address) {
        return deviceFor(address)?.connected ?? false;
    }

    function batteryLabel(address) {
        const device = deviceFor(address);
        return device?.batteryAvailable ? Math.round(device.battery * 100) + "%" : "";
    }

    // Follows the device being operated on to know when the operation ends.
    Connections {
        target: root.busyDevice
        ignoreUnknownSignals: true

        function onStateChanged() {
            const device = root.busyDevice;
            if (root.busyAction === "connect") {
                if (device.state === BluetoothDeviceState.Connecting)
                    root.busyStarted = true;
                else if (device.state === BluetoothDeviceState.Connected)
                    root.finishAction("");
                else if (device.state === BluetoothDeviceState.Disconnected && root.busyStarted)
                    root.finishAction(root.failureMessage("connect"));
            } else if (root.busyAction === "disconnect") {
                if (device.state === BluetoothDeviceState.Disconnected)
                    root.finishAction("");
            }
        }

        function onPairingChanged() {
            const device = root.busyDevice;
            if (root.busyAction !== "pair")
                return;
            if (device.pairing)
                root.busyStarted = true;
            else if (root.busyStarted && !device.paired)
                root.finishAction(root.failureMessage("pair"));
        }

        function onPairedChanged() {
            const device = root.busyDevice;
            if (root.busyAction === "pair" && device.paired) {
                // Trusted devices reconnect on their own later.
                device.trusted = true;
                root.finishAction("");
            } else if (root.busyAction === "forget" && !device.paired) {
                root.finishAction("");
            }
        }
    }

    Timer {
        id: actionTimeout
        repeat: false
        onTriggered: {
            const action = root.busyAction;
            const device = root.busyDevice;
            if (action === "")
                return;
            // A forgotten device may simply vanish from the list: that is success.
            if (action === "forget" && (!device || !root.deviceFor(root.busyAddress)?.paired)) {
                root.finishAction("");
                return;
            }
            if (action === "pair" && device?.pairing)
                device.cancelPair();
            root.finishAction(root.failureMessage(action));
        }
    }

    Timer {
        id: scanTimer
        interval: 8000
        repeat: false
        onTriggered: root.stopScan()
    }

    Timer {
        id: pairStartTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (BluetoothPairingAgent.ready && root.busyDevice) {
                root.busyDevice.pair();
            } else {
                root.finishAction(BluetoothPairingAgent.status || "Pairing agent unavailable.");
            }
        }
    }

    Process {
        id: unblockProcess

        command: ["rfkill", "unblock", "bluetooth"]

        onExited: code => {
            if (code === 0) {
                // The adapter may only appear after the unblock; onAdapterChanged finishes it.
                if (root.adapter && root.adapter.state !== BluetoothAdapterState.Blocked)
                    Qt.callLater(() => root.adapter.enabled = true);
                else
                    root.enableWhenReady = true;
            } else {
                root.actionMessage = "The system did not allow unblocking Bluetooth (rfkill).";
            }
        }
    }
}
