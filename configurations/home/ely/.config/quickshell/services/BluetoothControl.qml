pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// State and operations behind the Bluetooth section of the Arch Menu.
// The menu only renders this state; commands run through bluetoothctl.
Singleton {
    id: root

    // Set by the Arch Menu while it is visible; gates polling and agent cleanup.
    property bool menuVisible: false
    property bool expanded: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
    readonly property bool scanning: adapter?.discovering ?? false

    property var devices: []
    property var connected: []
    property var pairedDevices: []
    property var knownDevices: []
    property string actionMessage: ""
    property string busyAddress: ""
    property string busyAction: ""
    property string pendingForgetAddress: ""

    onEnabledChanged: {
        if (!enabled) {
            expanded = false;
            pairedDevices = [];
            knownDevices = [];
            devices = [];
            connected = [];
            scanTimer.stop();
            BluetoothPairingAgent.release();
        } else if (expanded) {
            BluetoothPairingAgent.ensureStarted();
            devicesProcess.running = true;
            knownDevicesProcess.running = true;
            connectedProcess.running = true;
        }
    }

    // Releases the pairing agent unless a pairing is still in progress.
    function releaseAgentIfIdle() {
        if (busyAction !== "pair" && busyAction !== "trust"
                && BluetoothPairingAgent.promptType === "")
            BluetoothPairingAgent.release();
    }

    function cleanup() {
        scanTimer.stop();
        stopScan();
        releaseAgentIfIdle();
    }

    function refresh() {
        if (enabled && expanded) {
            devicesProcess.running = true;
            knownDevicesProcess.running = true;
            connectedProcess.running = true;
        }
    }

    function updateDevices() {
        const result = pairedDevices.slice();
        for (const device of knownDevices) {
            if (!result.some(paired => paired.address === device.address))
                result.push({ address: device.address, name: device.name, paired: false });
        }
        result.sort((a, b) => {
            const aConnected = isConnected(a.address);
            const bConnected = isConnected(b.address);
            if (aConnected !== bConnected)
                return aConnected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            const aHasName = a.name !== a.address;
            const bHasName = b.name !== b.address;
            if (aHasName !== bHasName)
                return aHasName ? -1 : 1;
            return a.name.localeCompare(b.name, undefined, { sensitivity: "base" });
        });
        devices = result;
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
        if (expanded) {
            setExpanded(false);
        } else if (enabled) {
            setExpanded(true);
        }
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
            devicesProcess.running = true;
            knownDevicesProcess.running = true;
            connectedProcess.running = true;
            startScan();
        } else if (busyAction !== "pair" && busyAction !== "trust"
                && BluetoothPairingAgent.promptType === "") {
            stopScan();
            BluetoothPairingAgent.release();
        } else {
            stopScan();
        }
    }

    function connectDevice(address) {
        if (busyAction !== "") return;
        actionMessage = "";
        busyAddress = address;
        busyAction = "connect";
        connectProcess.exec(["bluetoothctl", "connect", address]);
    }

    function disconnectDevice(address) {
        if (busyAction !== "") return;
        actionMessage = "";
        busyAddress = address;
        busyAction = "disconnect";
        disconnectProcess.exec(["bluetoothctl", "disconnect", address]);
    }

    function pairDevice(address) {
        if (busyAction !== "") return;
        actionMessage = "";
        busyAddress = address;
        busyAction = "pair";
        BluetoothPairingAgent.ensureStarted();
        pairStartTimer.restart();
    }

    function forgetDevice(address) {
        if (busyAction !== "") return;
        pendingForgetAddress = address;
    }

    function confirmForget() {
        if (pendingForgetAddress === "") return;
        actionMessage = "";
        busyAddress = pendingForgetAddress;
        busyAction = "forget";
        forgetProcess.exec(["bluetoothctl", "remove", pendingForgetAddress]);
        pendingForgetAddress = "";
    }

    function deviceName(address) {
        const device = devices.find(entry => entry.address === address);
        return device?.name ?? address;
    }

    function refreshDevices() {
        if (!devicesProcess.running)
            devicesProcess.running = true;
        if (!knownDevicesProcess.running)
            knownDevicesProcess.running = true;
        if (!connectedProcess.running)
            connectedProcess.running = true;
    }

    function completeAction(action, address, code) {
        busyAddress = "";
        busyAction = "";
        if (code !== 0) {
            actionMessage = action === "pair"
                ? "Could not pair. Check that the device is in pairing mode."
                : action === "connect" ? "Could not connect to the device."
                : action === "disconnect" ? "Could not disconnect the device."
                : "Could not remove the paired device.";
            if (!menuVisible && BluetoothPairingAgent.promptType === "")
                BluetoothPairingAgent.release();
            return;
        }
        actionMessage = "";
        if (action === "pair") {
            busyAddress = address;
            busyAction = "trust";
            trustProcess.exec(["bluetoothctl", "trust", address]);
            return;
        }
        refreshDevices();
        if (!menuVisible && BluetoothPairingAgent.promptType === "")
            BluetoothPairingAgent.release();
    }

    function startScan() {
        if (!enabled)
            return;

        if (adapter)
            adapter.discovering = true;
        knownDevicesProcess.running = true;
        scanTimer.restart();
    }

    function stopScan() {
        scanTimer.stop();
        if (adapter)
            adapter.discovering = false;
    }

    function isConnected(address) {
        return connected.indexOf(address) !== -1;
    }

    function batteryLabel(address) {
        const liveDevices = Bluetooth.devices.values;
        const device = liveDevices.find(entry => entry.address === address);
        return device?.batteryAvailable ? Math.round(device.battery * 100) + "%" : "";
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.menuVisible && root.expanded && root.enabled
        onTriggered: root.refresh()
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
            if (BluetoothPairingAgent.ready && root.busyAddress !== "") {
                pairProcess.exec(["bluetoothctl", "pair", root.busyAddress]);
            } else {
                root.busyAddress = "";
                root.busyAction = "";
                root.actionMessage = BluetoothPairingAgent.status || "Pairing agent unavailable.";
            }
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.menuVisible && root.scanning
        onTriggered: {
            if (!knownDevicesProcess.running)
                knownDevicesProcess.running = true;
        }
    }

    Process {
        id: unblockProcess

        command: ["rfkill", "unblock", "bluetooth"]

        onExited: (code) => {
            if (code === 0) {
                Qt.callLater(() => {
                    if (root.adapter)
                        root.adapter.enabled = true;
                });
            } else {
                root.actionMessage = "The system did not allow unblocking Bluetooth (rfkill).";
            }
        }
    }

    Process {
        id: devicesProcess

        command: ["bluetoothctl", "devices", "Paired"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (let line of text.trim().split("\n")) {
                    const match = line.trim().match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
                    if (match)
                        result.push({ address: match[1], name: match[2], paired: true });
                }
                root.pairedDevices = result;
                root.updateDevices();
            }
        }
    }

    Process {
        id: knownDevicesProcess

        command: ["bluetoothctl", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const match = line.trim().match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
                    if (match)
                        result.push({ address: match[1], name: match[2] });
                }
                root.knownDevices = result;
                root.updateDevices();
            }
        }
    }

    Process {
        id: connectedProcess

        command: ["bluetoothctl", "devices", "Connected"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const match = line.match(/^Device\s+([0-9A-Fa-f:]{17})/);
                    if (match)
                        result.push(match[1]);
                }
                root.connected = result;
                root.updateDevices();
            }
        }
    }

    Process {
        id: connectProcess

        onExited: (code) => root.completeAction("connect", root.busyAddress, code)
    }

    Process {
        id: pairProcess

        onExited: (code) => root.completeAction("pair", root.busyAddress, code)
    }

    Process {
        id: disconnectProcess

        onExited: (code) => root.completeAction("disconnect", root.busyAddress, code)
    }

    Process {
        id: trustProcess

        onExited: (code) => {
            root.busyAddress = "";
            root.busyAction = "";
            if (code !== 0)
                root.actionMessage = "Paired, but could not mark the device as trusted.";
            root.refreshDevices();
            if (!root.menuVisible && BluetoothPairingAgent.promptType === "")
                BluetoothPairingAgent.release();
        }
    }

    Process {
        id: forgetProcess

        onExited: (code) => root.completeAction("forget", root.busyAddress, code)
    }
}
