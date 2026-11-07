pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// State and operations behind the Wi-Fi section of the Arch Menu.
// Uses the native Quickshell Networking API; the menu only renders this state.
Singleton {
    id: root

    // Emitted when a secured network needs a password so the UI can focus the field.
    signal passwordRequested()

    readonly property var device: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wifi)
                return device;
        }
        return null;
    }
    readonly property var networks: {
        const list = device?.networks?.values ?? [];
        const sorted = list.slice();
        sorted.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
        });
        return sorted;
    }
    readonly property var activeNetwork: networks.find(network => network.connected) ?? null
    readonly property bool enabled: Networking.wifiEnabled
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property string name: activeNetwork?.name ?? "Disconnected"

    property var pendingNetwork: null
    property string errorText: ""
    property bool expanded: false
    property string password: ""
    property string pendingSsid: ""
    property bool showPassword: false
    property bool showAll: false

    onEnabledChanged: {
        if (enabled && expanded && device) {
            device.scannerEnabled = true;
            scanStopTimer.restart();
        } else if (!enabled && device) {
            device.scannerEnabled = false;
            scanStopTimer.stop();
        }
    }

    function cleanup() {
        scanStopTimer.stop();
        if (device)
            device.scannerEnabled = false;
    }

    // Resets the transient UI state when the menu opens.
    function reset() {
        expanded = false;
        showAll = false;
        showPassword = false;
        password = "";
    }

    function toggle() {
        errorText = "";
        if (!hardwareEnabled) {
            errorText = "The Wi-Fi adapter is blocked by the system.";
            return;
        }
        if (Networking.wifiEnabled) {
            if (device)
                device.scannerEnabled = false;
            expanded = false;
            showAll = false;
            showPassword = false;
        }
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleExpanded() {
        if (!enabled)
            return;
        expanded = !expanded;
        if (expanded) {
            BluetoothControl.expanded = false;
            errorText = "";
            if (device) {
                device.scannerEnabled = true;
                scanStopTimer.restart();
            }
        } else {
            scanStopTimer.stop();
            if (device)
                device.scannerEnabled = false;
        }
    }

    function toggleDetails() {
        if (expanded) {
            expanded = false;
            scanStopTimer.stop();
            if (device)
                device.scannerEnabled = false;
            return;
        }
        BluetoothControl.expanded = false;
        expanded = true;
        errorText = hardwareEnabled ? "" : "The Wi-Fi adapter is blocked by the system.";
        if (enabled && device) {
            device.scannerEnabled = true;
            scanStopTimer.restart();
        }
    }

    function connect(network) {
        if (!network) return;
        errorText = "";
        pendingNetwork = network;
        network.connect();
    }

    function handleConnectionFailure(network, reason) {
        if (reason === ConnectionFailReason.NoSecrets) {
            pendingNetwork = network;
            pendingSsid = network.name;
            password = "";
            errorText = "";
            showPassword = true;
            passwordRequested();
            return;
        }
        errorText = "Failed to connect to " + network.name + ": " + ConnectionFailReason.toString(reason);
    }

    function connectSecured() {
        if (!pendingNetwork || password === "")
            return;
        errorText = "";
        const pskSecurity = pendingNetwork.security === WifiSecurityType.WpaPsk
            || pendingNetwork.security === WifiSecurityType.Wpa2Psk
            || pendingNetwork.security === WifiSecurityType.Sae;
        if (pskSecurity && pendingNetwork.connectWithPsk)
            pendingNetwork.connectWithPsk(password);
        else
            errorText = "This network requires advanced credentials that the menu does not support yet.";
        showPassword = false;
        password = "";
        pendingSsid = "";
        pendingNetwork = null;
    }

    function refreshNetworks() {
        if (!device)
            return;
        device.scannerEnabled = false;
        Qt.callLater(() => {
            if (root.expanded && root.enabled && root.device) {
                root.device.scannerEnabled = true;
                scanStopTimer.restart();
            }
        });
    }

    Timer {
        id: scanStopTimer
        interval: 8000
        repeat: false
        onTriggered: {
            if (root.device)
                root.device.scannerEnabled = false;
        }
    }
}
