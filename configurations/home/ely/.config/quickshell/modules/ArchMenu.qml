import ".." as Config
import "../services" as Services
import "../widgets" as Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as QsModules
import "./PopupGeometry.js" as PopupGeometry
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property var positionProvider
    property real popupRight: 16
    property real enterProgress: 0
    property string uptimeText: "Up …"
    property string activeTab: "notifications"
    readonly property bool compactLayout: (targetScreen?.height ?? 720) < 800
    readonly property bool compactWidth: implicitWidth < 360
    readonly property var pipewire: Services.Volume.pipewire
    readonly property var outputDevices: Services.Volume.outputDevices
    readonly property var inputDevices: Services.Volume.inputDevices
    readonly property var outputAppNodes: Services.Volume.outputAppNodes
    readonly property var wifiDevice: {
        for (const device of Networking.devices.values) {
            if (device.type === DeviceType.Wifi)
                return device;
        }
        return null;
    }
    readonly property var wifiNetworks: {
        const networks = wifiDevice?.networks?.values ?? [];
        const sorted = networks.slice();
        sorted.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.known !== b.known)
                return a.known ? -1 : 1;
            return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
        });
        return sorted;
    }
    readonly property var activeWifiNetwork: wifiNetworks.find(network => network.connected) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property string wifiName: activeWifiNetwork?.name ?? "Disconnected"
    property var pendingWifiNetwork: null
    property string wifiErrorText: ""
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: bluetoothAdapter?.enabled ?? false
    readonly property bool bluetoothBlocked: bluetoothAdapter?.state === BluetoothAdapterState.Blocked
    property var bluetoothDevices: []
    property var bluetoothConnected: []
    property var bluetoothPairedDevices: []
    property var bluetoothKnownDevices: []
    property string bluetoothActionMessage: ""
    property string bluetoothBusyAddress: ""
    property string bluetoothBusyAction: ""
    property string pendingForgetAddress: ""
    property bool wifiExpanded: false
    property bool bluetoothExpanded: false
    readonly property bool scanningBluetooth: bluetoothAdapter?.discovering ?? false
    property string wifiPassword: ""
    property string pendingWifiSsid: ""
    property bool showWifiPassword: false
    property bool wifiShowAll: false
    property int wifiInitialVisibleCount: 6
    readonly property int wifiMaxHeight: Math.max(72, Math.min(280, (screen?.height ?? 720) * 0.28))
    readonly property int bluetoothMaxHeight: Math.max(72, Math.min(200, (screen?.height ?? 720) * 0.22))

    function ensureItemVisible(flickable, itemY, itemHeight) {
        const maxContentY = Math.max(0, flickable.contentHeight - flickable.height);
        if (itemY < flickable.contentY)
            flickable.contentY = Math.max(0, itemY);
        else if (itemY + itemHeight > flickable.contentY + flickable.height)
            flickable.contentY = Math.min(maxContentY, itemY + itemHeight - flickable.height);
    }

    function revealNetworkRow(row, list) {
        ensureItemVisible(list, row.y, row.height);
        Qt.callLater(() => {
            const viewport = content.contentItem;
            const position = row.mapToItem(viewport, 0, 0);
            ensureItemVisible(viewport, position.y, row.height);
        });
    }

    function openMenu() {
        popupRight = positionProvider(implicitWidth).right ?? 16;
        // The panel always opens on the main tab, like end-4's quick settings.
        activeTab = "notifications";
        wifiExpanded = false;
        bluetoothExpanded = false;
        wifiShowAll = false;
        showWifiPassword = false;
        wifiPassword = "";
        refresh();
        uptimeProcess.exec(["cat", "/proc/uptime"]);
        visible = true;
    }

    Connections {
        target: Services.Notifications
        function onCenterRequestedTabChanged() {
            if (root.visible)
                root.activeTab = Services.Notifications.centerRequestedTab;
        }
    }

    function formatUptime(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (days > 0)
            return "Up " + days + "d " + hours + "h";
        if (hours > 0)
            return "Up " + hours + "h " + minutes + " min";
        return minutes > 0 ? "Up " + minutes + " min" : "Up less than 1 min";
    }

    function audioNodeName(node) {
        return node?.nickname || node?.description || node?.name || "Audio device";
    }

    function audioDeviceIndex(devices, preferredDevice, currentDevice) {
        const currentIndex = currentDevice ? devices.indexOf(currentDevice) : -1;
        if (currentIndex >= 0)
            return currentIndex;

        const preferredIndex = preferredDevice ? devices.indexOf(preferredDevice) : -1;
        return preferredIndex;
    }

    function audioAppName(node) {
        const properties = node?.properties ?? {};
        const application = properties["application.name"]
            || node?.description || node?.name || "Application";
        const media = properties["media.name"];
        return media && media !== application ? application + " · " + media : application;
    }

    function selectOutputDevice(index) {
        if (index >= 0 && index < outputDevices.length)
            pipewire.preferredDefaultAudioSink = outputDevices[index];
    }

    function selectInputDevice(index) {
        if (index >= 0 && index < inputDevices.length)
            pipewire.preferredDefaultAudioSource = inputDevices[index];
    }

    function toggleAppMute(node) {
        Services.Volume.toggleNodeMute(node);
    }

    function setAppVolume(node, value) {
        Services.Volume.setNodeVolume(node, value);
    }

    onVisibleChanged: {
        if (!visible) {
            enterProgress = 0;
            Services.Notifications.closeCenter();
            cleanupTransientActions();
        } else {
            openAnimation.restart();
            Qt.callLater(() => wifiPowerButton.forceActiveFocus());
        }
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "enterProgress"
        from: 0
        to: 1
        duration: Config.Theme.motionEnter
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveEnter
    }

    onActiveTabChanged: {
        if (Services.Notifications.centerRequestedTab !== activeTab)
            Services.Notifications.centerRequestedTab = activeTab;
        Qt.callLater(() => {
            if (content.contentItem)
                content.contentItem.contentY = 0;
        });
    }

    Component.onDestruction: cleanupTransientActions()

    function cleanupTransientActions() {
        wifiScanStopTimer.stop();
        bluetoothScanTimer.stop();
        if (wifiDevice)
            wifiDevice.scannerEnabled = false;
        stopBluetoothScan();
        if (bluetoothBusyAction !== "pair" && bluetoothBusyAction !== "trust"
                && Services.BluetoothPairingAgent.promptType === "")
            Services.BluetoothPairingAgent.release();
    }

    onBluetoothEnabledChanged: {
        if (!bluetoothEnabled) {
            bluetoothExpanded = false;
            bluetoothPairedDevices = [];
            bluetoothKnownDevices = [];
            bluetoothDevices = [];
            bluetoothConnected = [];
            bluetoothScanTimer.stop();
            Services.BluetoothPairingAgent.release();
        } else if (bluetoothExpanded) {
            Services.BluetoothPairingAgent.ensureStarted();
            bluetoothDevicesProcess.running = true;
            bluetoothKnownDevicesProcess.running = true;
            bluetoothConnectedProcess.running = true;
        }
    }

    onWifiEnabledChanged: {
        if (wifiEnabled && wifiExpanded && wifiDevice) {
            wifiDevice.scannerEnabled = true;
            wifiScanStopTimer.restart();
        } else if (!wifiEnabled && wifiDevice) {
            wifiDevice.scannerEnabled = false;
            wifiScanStopTimer.stop();
        }
    }

    function refresh() {
        if (bluetoothEnabled && bluetoothExpanded) {
            bluetoothDevicesProcess.running = true;
            bluetoothKnownDevicesProcess.running = true;
            bluetoothConnectedProcess.running = true;
        }
    }

    function updateBluetoothDevices() {
        const result = bluetoothPairedDevices.slice();
        for (const device of bluetoothKnownDevices) {
            if (!result.some(paired => paired.address === device.address))
                result.push({ address: device.address, name: device.name, paired: false });
        }
        result.sort((a, b) => {
            const aConnected = isBluetoothConnected(a.address);
            const bConnected = isBluetoothConnected(b.address);
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
        root.bluetoothDevices = result;
    }

    function toggleWifi() {
        wifiErrorText = "";
        if (!wifiHardwareEnabled) {
            wifiErrorText = "The Wi-Fi adapter is blocked by the system.";
            return;
        }
        if (Networking.wifiEnabled) {
            if (wifiDevice)
                wifiDevice.scannerEnabled = false;
            wifiExpanded = false;
            wifiShowAll = false;
            showWifiPassword = false;
        }
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleBluetooth() {
        if (bluetoothEnabled) {
            bluetoothExpanded = false;
            stopBluetoothScan();
        } else if (bluetoothBlocked) {
            bluetoothActionMessage = "";
            bluetoothUnblockProcess.running = true;
            return;
        }
        if (bluetoothAdapter)
            bluetoothAdapter.enabled = !bluetoothEnabled;
    }

    function toggleWifiExpanded() {
        if (!wifiEnabled)
            return ;
        wifiExpanded = !wifiExpanded;
        if (wifiExpanded) {
            bluetoothExpanded = false;
            wifiErrorText = "";
            if (wifiDevice) {
                wifiDevice.scannerEnabled = true;
                wifiScanStopTimer.restart();
            }
        } else {
            wifiScanStopTimer.stop();
            if (wifiDevice)
                wifiDevice.scannerEnabled = false;
        }
    }

    function toggleWifiDetails() {
        if (wifiExpanded) {
            wifiExpanded = false;
            wifiScanStopTimer.stop();
            if (wifiDevice)
                wifiDevice.scannerEnabled = false;
            return;
        }
        bluetoothExpanded = false;
        wifiExpanded = true;
        wifiErrorText = wifiHardwareEnabled ? "" : "The Wi-Fi adapter is blocked by the system.";
        if (wifiEnabled && wifiDevice) {
            wifiDevice.scannerEnabled = true;
            wifiScanStopTimer.restart();
        }
    }

    function toggleBluetoothDetails() {
        setBluetoothExpanded(!bluetoothExpanded);
    }

    function toggleBluetoothExpanded() {
        if (bluetoothExpanded) {
            setBluetoothExpanded(false);
        } else if (bluetoothEnabled) {
            setBluetoothExpanded(true);
        }
    }

    function setBluetoothExpanded(expanded) {
        if (bluetoothExpanded === expanded)
            return;

        bluetoothExpanded = expanded;
        if (expanded) {
            wifiExpanded = false;
            if (!bluetoothEnabled)
                return;
            Services.BluetoothPairingAgent.ensureStarted();
            bluetoothDevicesProcess.running = true;
            bluetoothKnownDevicesProcess.running = true;
            bluetoothConnectedProcess.running = true;
            startBluetoothScan();
        } else if (bluetoothBusyAction !== "pair" && bluetoothBusyAction !== "trust"
                && Services.BluetoothPairingAgent.promptType === "") {
            stopBluetoothScan();
            Services.BluetoothPairingAgent.release();
        } else {
            stopBluetoothScan();
        }
    }

    function connectWifi(network) {
        if (!network) return;
        wifiErrorText = "";
        pendingWifiNetwork = network;
        network.connect();
    }

    function handleWifiConnectionFailure(network, reason) {
        if (reason === ConnectionFailReason.NoSecrets) {
            pendingWifiNetwork = network;
            pendingWifiSsid = network.name;
            wifiPassword = "";
            wifiErrorText = "";
            showWifiPassword = true;
            Qt.callLater(() => wifiPasswordField.forceActiveFocus());
            return;
        }
        wifiErrorText = "Failed to connect to " + network.name + ": " + ConnectionFailReason.toString(reason);
    }

    function connectSecuredWifi() {
        if (!pendingWifiNetwork || wifiPassword === "")
            return ;
        wifiErrorText = "";
        const pskSecurity = pendingWifiNetwork.security === WifiSecurityType.WpaPsk
            || pendingWifiNetwork.security === WifiSecurityType.Wpa2Psk
            || pendingWifiNetwork.security === WifiSecurityType.Sae;
        if (pskSecurity && pendingWifiNetwork.connectWithPsk)
            pendingWifiNetwork.connectWithPsk(wifiPassword);
        else
            wifiErrorText = "This network requires advanced credentials that the menu does not support yet.";
        showWifiPassword = false;
        wifiPassword = "";
        pendingWifiSsid = "";
        pendingWifiNetwork = null;
    }

    function connectBluetooth(address) {
        if (bluetoothBusyAction !== "") return;
        bluetoothActionMessage = "";
        bluetoothBusyAddress = address;
        bluetoothBusyAction = "connect";
        bluetoothConnectProcess.exec(["bluetoothctl", "connect", address]);
    }

    function disconnectBluetooth(address) {
        if (bluetoothBusyAction !== "") return;
        bluetoothActionMessage = "";
        bluetoothBusyAddress = address;
        bluetoothBusyAction = "disconnect";
        bluetoothDisconnectProcess.exec(["bluetoothctl", "disconnect", address]);
    }

    function pairBluetooth(address) {
        if (bluetoothBusyAction !== "") return;
        bluetoothActionMessage = "";
        bluetoothBusyAddress = address;
        bluetoothBusyAction = "pair";
        Services.BluetoothPairingAgent.ensureStarted();
        bluetoothPairStartTimer.restart();
    }

    function forgetBluetooth(address) {
        if (bluetoothBusyAction !== "") return;
        pendingForgetAddress = address;
    }

    function confirmBluetoothForget() {
        if (pendingForgetAddress === "") return;
        bluetoothActionMessage = "";
        bluetoothBusyAddress = pendingForgetAddress;
        bluetoothBusyAction = "forget";
        bluetoothForgetProcess.exec(["bluetoothctl", "remove", pendingForgetAddress]);
        pendingForgetAddress = "";
    }

    function bluetoothName(address) {
        const device = bluetoothDevices.find(entry => entry.address === address);
        return device?.name ?? address;
    }

    function refreshBluetoothDevices() {
        if (!bluetoothDevicesProcess.running)
            bluetoothDevicesProcess.running = true;
        if (!bluetoothKnownDevicesProcess.running)
            bluetoothKnownDevicesProcess.running = true;
        if (!bluetoothConnectedProcess.running)
            bluetoothConnectedProcess.running = true;
    }

    function completeBluetoothAction(action, address, code) {
        bluetoothBusyAddress = "";
        bluetoothBusyAction = "";
        if (code !== 0) {
            bluetoothActionMessage = action === "pair"
                ? "Could not pair. Check that the device is in pairing mode."
                : action === "connect" ? "Could not connect to the device."
                : action === "disconnect" ? "Could not disconnect the device."
                : "Could not remove the paired device.";
            if (!visible && Services.BluetoothPairingAgent.promptType === "")
                Services.BluetoothPairingAgent.release();
            return;
        }
        bluetoothActionMessage = "";
        if (action === "pair") {
            bluetoothBusyAddress = address;
            bluetoothBusyAction = "trust";
            bluetoothTrustProcess.exec(["bluetoothctl", "trust", address]);
            return;
        }
        refreshBluetoothDevices();
        if (!visible && Services.BluetoothPairingAgent.promptType === "")
            Services.BluetoothPairingAgent.release();
    }

    function startBluetoothScan() {
        if (!bluetoothEnabled)
            return ;

        if (bluetoothAdapter)
            bluetoothAdapter.discovering = true;
        bluetoothKnownDevicesProcess.running = true;
        bluetoothScanTimer.restart();
    }

    function stopBluetoothScan() {
        bluetoothScanTimer.stop();
        if (bluetoothAdapter)
            bluetoothAdapter.discovering = false;
    }

    function isBluetoothConnected(address) {
        return bluetoothConnected.indexOf(address) !== -1;
    }

    function bluetoothBatteryLabel(address) {
        const liveDevices = Bluetooth.devices.values;
        const device = liveDevices.find(entry => entry.address === address);
        return device?.batteryAvailable ? Math.round(device.battery * 100) + "%" : "";
    }

    function wifiSignalIcon(signal) {
        if (signal >= 80)
            return "signal_wifi_4_bar";

        if (signal >= 60)
            return "network_wifi_3_bar";

        if (signal >= 35)
            return "network_wifi_2_bar";

        if (signal > 0)
            return "network_wifi_1_bar";

        return "signal_wifi_0_bar";
    }

    function wifiSecurityIcon(security) {
        return security === WifiSecurityType.Open ? "lock_open" : "lock";
    }

    function refreshWifiNetworks() {
        if (!wifiDevice)
            return;
        wifiDevice.scannerEnabled = false;
        Qt.callLater(() => {
            if (root.wifiExpanded && root.wifiEnabled && root.wifiDevice) {
                root.wifiDevice.scannerEnabled = true;
                wifiScanStopTimer.restart();
            }
        });
    }

    color: "transparent"
    visible: false
    focusable: visible
    screen: targetScreen
    implicitWidth: PopupGeometry.widthForScreen(targetScreen, 420, 24)
    implicitHeight: Math.max(1,
        (targetScreen?.height ?? 720) - Config.Theme.barHeight - 24
    )
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        right: root.popupRight
        bottom: 8
    }

    Widgets.FocusDismissBehavior {
        window: root
        dismissAction: () => root.visible = false
    }

    contentItem {
        focus: root.visible
        Keys.onEscapePressed: root.visible = false
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.visible && root.bluetoothExpanded && root.bluetoothEnabled
        onTriggered: root.refresh()
    }

    Timer {
        id: bluetoothScanTimer

        interval: 8000
        repeat: false
        onTriggered: root.stopBluetoothScan()
    }

    Timer {
        id: bluetoothPairStartTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (Services.BluetoothPairingAgent.ready && root.bluetoothBusyAddress !== "") {
                bluetoothPairProcess.exec(["bluetoothctl", "pair", root.bluetoothBusyAddress]);
            } else {
                root.bluetoothBusyAddress = "";
                root.bluetoothBusyAction = "";
                root.bluetoothActionMessage = Services.BluetoothPairingAgent.status || "Pairing agent unavailable.";
            }
        }
    }

    Timer {
        id: wifiScanStopTimer
        interval: 8000
        repeat: false
        onTriggered: {
            if (root.wifiDevice)
                root.wifiDevice.scannerEnabled = false;
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.visible && root.scanningBluetooth
        onTriggered: {
            if (!bluetoothKnownDevicesProcess.running)
                bluetoothKnownDevicesProcess.running = true;
        }
    }

    Process {
        id: uptimeProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = Number(text.trim().split(/\s+/)[0]);
                if (Number.isFinite(seconds) && seconds >= 0)
                    root.uptimeText = root.formatUptime(Math.floor(seconds));
            }
        }
    }

    Process {
        id: bluetoothUnblockProcess

        command: ["rfkill", "unblock", "bluetooth"]

        onExited: (code) => {
            if (code === 0) {
                Qt.callLater(() => {
                    if (root.bluetoothAdapter)
                        root.bluetoothAdapter.enabled = true;
                });
            } else {
                root.bluetoothActionMessage = "The system did not allow unblocking Bluetooth (rfkill).";
            }
        }
    }

    Process {
        id: bluetoothDevicesProcess

        command: ["bluetoothctl", "devices", "Paired"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                const lines = text.trim().split("\n");
                for (let line of lines) {
                    line = line.trim();
                    if (!line.startsWith("Device "))
                        continue;

                    const match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
                    if (!match)
                        continue;

                    result.push({
                        "address": match[1],
                        "name": match[2]
                    });
                }
                root.bluetoothPairedDevices = result.map(device => ({ address: device.address, name: device.name, paired: true }));
                root.updateBluetoothDevices();
            }
        }

    }

    Process {
        id: bluetoothKnownDevicesProcess

        command: ["bluetoothctl", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const match = line.trim().match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
                    if (match)
                        result.push({ address: match[1], name: match[2] });
                }
                root.bluetoothKnownDevices = result;
                root.updateBluetoothDevices();
            }
        }
    }

    Process {
        id: bluetoothConnectedProcess

        command: ["bluetoothctl", "devices", "Connected"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                const lines = text.trim().split("\n");
                for (let line of lines) {
                    const match = line.match(/^Device\s+([0-9A-Fa-f:]{17})/);
                    if (match)
                        result.push(match[1]);

                }
                root.bluetoothConnected = result;
                root.updateBluetoothDevices();
            }
        }

    }

    Process {
        id: bluetoothConnectProcess

        onExited: (code) => root.completeBluetoothAction("connect", root.bluetoothBusyAddress, code)
    }

    Process {
        id: bluetoothPairProcess

        onExited: (code) => root.completeBluetoothAction("pair", root.bluetoothBusyAddress, code)
    }

    Process {
        id: bluetoothDisconnectProcess

        onExited: (code) => root.completeBluetoothAction("disconnect", root.bluetoothBusyAddress, code)
    }

    Process {
        id: bluetoothTrustProcess
        onExited: (code) => {
            root.bluetoothBusyAddress = "";
            root.bluetoothBusyAction = "";
            if (code !== 0)
                root.bluetoothActionMessage = "Paired, but could not mark the device as trusted.";
            root.refreshBluetoothDevices();
            if (!root.visible && Services.BluetoothPairingAgent.promptType === "")
                Services.BluetoothPairingAgent.release();
        }
    }

    Process {
        id: bluetoothForgetProcess
        onExited: (code) => root.completeBluetoothAction("forget", root.bluetoothBusyAddress, code)
    }

    Widgets.SurfaceCard {
        anchors.fill: parent
        opacity: root.enterProgress
        transform: Translate { y: (1 - root.enterProgress) * -10 }
        surfaceColor: Config.Theme.colPanel
        cornerRadius: Config.Theme.radiusPanel
        outlineOpacity: 0.72
    }

    ScrollView {
        id: content
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: sidebarCalendar.top
            topMargin: Config.Theme.spaceLg
            leftMargin: Config.Theme.spaceLg
            rightMargin: Config.Theme.spaceLg
            bottomMargin: Config.Theme.spaceSm
        }
        clip: true
        contentWidth: availableWidth
        ScrollBar.vertical: Widgets.ThemeScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentColumn
            width: content.availableWidth
            height: Math.max(content.height, implicitHeight)
            spacing: Config.Theme.spaceSm

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "timer"
                color: Config.Theme.colHighlight
                font.family: "Material Symbols Rounded"
                font.pixelSize: 21
            }

            Text {
                Layout.fillWidth: true
                text: root.uptimeText
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                font.bold: true
            }

            Widgets.IconButton {
                iconName: "close"
                implicitWidth: 34
                implicitHeight: 34
                Accessible.name: "Close panel"
                onClicked: Services.Notifications.closeCenter()
            }

            Widgets.IconButton {
                id: wlogoutButton
                iconName: "power_settings_new"
                iconSize: 21
                buttonRadius: 10
                prominent: true
                filled: true
                idleIconColor: Config.Theme.colFg
                implicitWidth: 38
                implicitHeight: 36
                Accessible.name: "Open session options"
                ToolTip.text: "Open wlogout"
                ToolTip.visible: hovered
                onClicked: {
                    Services.Notifications.closeCenter();
                    Services.WindowControl.toggleLogout();
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compactLayout ? 58 : 66
                Accessible.role: Accessible.Grouping

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: root.wifiEnabled
                        ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                  Config.Theme.colHighlight.b, 0.22)
                        : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                  Config.Theme.colTextSec.b, 0.12)
                    border.width: root.wifiEnabled ? 1 : 0
                    border.color: Config.Theme.colHighlight
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 5

                    Text {
                        text: root.wifiEnabled ? "wifi" : "wifi_off"
                        color: root.wifiEnabled ? Config.Theme.colHighlight : Config.Theme.colMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 19
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: "Wi-Fi"
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: root.compactWidth ? 10 : Config.Theme.fontSizeSmall
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.wifiEnabled ? root.wifiName
                                : (root.wifiHardwareEnabled ? "Disabled" : "Blocked")
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Widgets.IconButton {
                        id: wifiPowerButton
                        iconName: "power_settings_new"
                        selected: root.wifiEnabled
                        implicitWidth: 27
                        implicitHeight: 34
                        Accessible.name: root.wifiEnabled ? "Turn off Wi-Fi" : "Turn on Wi-Fi"
                        onClicked: root.toggleWifi()
                    }
                    Widgets.IconButton {
                        implicitWidth: 24
                        implicitHeight: 34
                        id: wifiDetailsButton
                        iconName: root.wifiExpanded ? "expand_less" : "chevron_right"
                        Accessible.name: root.wifiExpanded ? "Hide Wi-Fi networks" : "Show Wi-Fi networks"
                        onClicked: root.toggleWifiDetails()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compactLayout ? 58 : 66
                Accessible.role: Accessible.Grouping

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: root.bluetoothEnabled
                        ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                  Config.Theme.colHighlight.b, 0.22)
                        : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                  Config.Theme.colTextSec.b, 0.12)
                    border.width: root.bluetoothEnabled ? 1 : 0
                    border.color: Config.Theme.colHighlight
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 5
                    Text {
                        text: "bluetooth"
                        color: root.bluetoothEnabled ? Config.Theme.colHighlight : Config.Theme.colMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 19
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: "Bluetooth"
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: root.compactWidth ? 10 : Config.Theme.fontSizeSmall
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.bluetoothEnabled
                                ? (root.bluetoothConnected.length > 0 ? "Connected" : "On")
                                : "Disabled"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }
                    Widgets.IconButton {
                        id: bluetoothPowerButton
                        iconName: "power_settings_new"
                        selected: root.bluetoothEnabled
                        implicitWidth: 27
                        implicitHeight: 34
                        Accessible.name: root.bluetoothEnabled ? "Turn off Bluetooth" : "Turn on Bluetooth"
                        onClicked: root.toggleBluetooth()
                    }
                    Widgets.IconButton {
                        id: bluetoothDetailsButton
                        implicitWidth: 24
                        implicitHeight: 34
                        iconName: root.bluetoothExpanded ? "expand_less" : "chevron_right"
                        Accessible.name: root.bluetoothExpanded ? "Hide Bluetooth devices" : "Show Bluetooth devices"
                        onClicked: root.toggleBluetoothDetails()
                    }
                }
            }

            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: Services.Brightness.supported
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "brightness_6"
                        color: Config.Theme.colHighlight

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 20
                        }

                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Brightness"
                        color: Config.Theme.colFg

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSize
                            bold: true
                        }

                    }

                    Text {
                        text: Services.Brightness.percentage + "%"
                        color: Config.Theme.colMuted

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeSmall
                        }

                    }

                }

                Item {
                    id: brightnessControl
                    Layout.fillWidth: true
                    implicitHeight: 16
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Slider
                    Accessible.name: "Screen brightness"

                    Keys.onPressed: event => {
                        const current = Services.Brightness.brightness;
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down)
                            Services.Brightness.setBrightness(Math.max(0, current - 0.05));
                        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up)
                            Services.Brightness.setBrightness(Math.min(1, current + 0.05));
                        else if (event.key === Qt.Key_Home)
                            Services.Brightness.setBrightness(0);
                        else if (event.key === Qt.Key_End)
                            Services.Brightness.setBrightness(1);
                        else
                            return;
                        event.accepted = true;
                    }

                    Rectangle {
                        id: brightnessTrack

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.2)

                        Rectangle {
                            width: parent.width * Services.Brightness.brightness
                            height: parent.height
                            radius: parent.radius
                            color: Config.Theme.colHighlight
                        }

                    }

                    Rectangle {
                        x: brightnessTrack.width * Services.Brightness.brightness - width / 2
                        anchors.verticalCenter: brightnessTrack.verticalCenter
                        width: 14
                        height: 14
                        radius: 7
                        color: Config.Theme.colFg
                        border.width: brightnessControl.activeFocus ? 2 : 0
                        border.color: Config.Theme.colHighlight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            return Services.Brightness.setBrightness(mouse.x / width);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                Services.Brightness.setBrightness(mouse.x / width);

                        }
                    }

                }

            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: Services.Volume.captureApplications.length > 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.compactLayout ? 50 : 58
                visible: Services.Volume.captureApplications.length > 0
                Accessible.role: Accessible.Button
                Accessible.name: Services.Volume.microphoneMuted ? "Unmute microphone" : "Mute microphone"
                activeFocusOnTab: visible

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: micTileMouse.containsMouse || parent.activeFocus
                        ? Qt.rgba(Config.Theme.colRed.r, Config.Theme.colRed.g, Config.Theme.colRed.b, 0.18)
                        : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                  Config.Theme.colTextSec.b, 0.12)
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    Text {
                        text: Services.Volume.microphoneMuted ? "mic_off" : "mic"
                        color: Services.Volume.microphoneMuted ? Config.Theme.colTextSec : Config.Theme.colRed
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 19
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Services.Volume.captureApplications.join(", ")
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: micTileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Volume.toggleMicrophoneMute()
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        Services.Volume.toggleMicrophoneMute();
                        event.accepted = true;
                    }
                }
            }

            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Services.Media.connected
            implicitHeight: root.compactLayout ? 66 : 78
            radius: 12
            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                           Config.Theme.colTextSec.b, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.compactLayout ? 8 : 10
                spacing: root.compactLayout ? 6 : 10

                Rectangle {
                    Layout.preferredWidth: root.compactLayout ? 44 : 52
                    Layout.preferredHeight: root.compactLayout ? 44 : 52
                    radius: 8
                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                   Config.Theme.colTextSec.b, 0.18)
                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Config.Theme.colTextSec
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                    }
                    Image {
                        anchors.fill: parent
                        source: Services.Media.artUrl
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        sourceSize.width: 104
                        sourceSize.height: 104
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: Services.Media.displayTitle
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Services.Media.displayArtist
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                    Text {
                        text: Services.Media.displayName
                        color: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 9
                    }
                }

                Widgets.IconButton {
                    id: previousTrackButton
                    iconName: "skip_previous"
                    iconSize: 20
                    buttonRadius: 8
                    idleIconColor: Config.Theme.colFg
                    implicitWidth: 30
                    implicitHeight: 34
                    Accessible.name: "Previous track"
                    enabled: Services.Media.canPrevious
                    onClicked: Services.Media.previous()
                }
                Widgets.IconButton {
                    id: toggleTrackButton
                    iconName: Services.Media.playing ? "pause" : "play_arrow"
                    iconSize: 22
                    buttonRadius: 10
                    prominent: true
                    filled: true
                    idleIconColor: Config.Theme.colFg
                    implicitWidth: 34
                    implicitHeight: 34
                    Accessible.name: Services.Media.playing ? "Pause" : "Resume playback"
                    enabled: Services.Media.canToggle
                    onClicked: Services.Media.togglePlayPause()
                }
                Widgets.IconButton {
                    id: nextTrackButton
                    iconName: "skip_next"
                    iconSize: 20
                    buttonRadius: 8
                    idleIconColor: Config.Theme.colFg
                    implicitWidth: 30
                    implicitHeight: 34
                    Accessible.name: "Next track"
                    enabled: Services.Media.canNext
                    onClicked: Services.Media.next()
                }
            }
        }

        Rectangle {
            visible: root.wifiExpanded || root.showWifiPassword
            Layout.fillWidth: true
            implicitHeight: wifiColumn.implicitHeight + 20
            radius: 9
            color: wifiHover.hovered ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.18) : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.1)

            HoverHandler { id: wifiHover }

            ColumnLayout {
                id: wifiColumn

                spacing: 8

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: wifiHeader.implicitHeight

                    RowLayout {
                        id: wifiHeader
                        anchors.fill: parent

                    Text {
                        text: root.wifiEnabled ? "wifi" : "wifi_off"
                        color: root.wifiEnabled ? Config.Theme.colHighlight : Config.Theme.colMuted

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 22
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Wi-Fi"
                            color: Config.Theme.colFg

                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: Config.Theme.fontSize
                                bold: true
                            }

                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.wifiEnabled ? root.wifiName : "Disabled"
                            color: Config.Theme.colMuted
                            elide: Text.ElideRight

                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: Config.Theme.fontSizeSmall
                            }

                        }

                    }

                    Text {
                        text: root.wifiEnabled ? (root.wifiExpanded ? "expand_less" : "expand_more") : ""
                        color: Config.Theme.colMuted

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 20
                        }

                    }

                    Rectangle {
                        id: wifiToggle
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 22
                        radius: height / 2
                        color: root.wifiEnabled ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g, Config.Theme.colHighlight.b, 0.45) : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.35)

                        Rectangle {
                            x: root.wifiEnabled ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            radius: height / 2
                            color: root.wifiEnabled ? Config.Theme.colHighlight : Config.Theme.colFg
                            Behavior on x { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWifi()
                        }
                    }

                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleWifiExpanded()
                    }
                }

                /*
                * Wi-Fi network list
                */
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.wifiExpanded && root.wifiEnabled
                    spacing: 4

                    Repeater {
                        model: root.wifiNetworks
                        delegate: Item {
                            required property var modelData
                            width: 0
                            height: 0

                            Connections {
                                target: modelData
                                function onConnectionFailed(reason) {
                                    root.handleWifiConnectionFailure(modelData, reason);
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.2)
                    }

                    Flickable {
                        id: wifiFlickable

                        Layout.fillWidth: true
                        implicitHeight: Math.min(wifiNetworkColumn.implicitHeight, root.wifiMaxHeight)
                        contentWidth: width
                        contentHeight: wifiNetworkColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentHeight > height

                        ScrollBar.vertical: Widgets.ThemeScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.wifiNetworks.length === 0
                            text: root.wifiDevice?.scannerEnabled ? "Scanning for networks…" : "No networks found"
                            color: Config.Theme.colMuted
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                        }

                        Column {
                            id: wifiNetworkColumn

                            width: wifiFlickable.width
                            spacing: 4

                            Repeater {
                                model: root.wifiShowAll ? root.wifiNetworks : root.wifiNetworks.slice(0, root.wifiInitialVisibleCount)

                                delegate: Rectangle {
                                    required property var modelData

                                    width: wifiNetworkColumn.width
                                    height: 42
                                    radius: 7
                                    activeFocusOnTab: !modelData.stateChanging
                                    Accessible.role: Accessible.Button
                                    Accessible.name: modelData.name
                                        + (modelData.connected ? ", connected" : ", Wi-Fi network")
                                    color: activeFocus
                                        ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                                  Config.Theme.colHighlight.b, Config.Theme.stateSelectedOpacity)
                                        : (wifiNetworkMouse.containsMouse
                                            ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                                      Config.Theme.colTextSec.b, Config.Theme.stateHoverOpacity)
                                            : "transparent")
                                    border.width: activeFocus ? 1 : 0
                                    border.color: Config.Theme.colHighlight

                                    onActiveFocusChanged: {
                                        if (activeFocus)
                                            root.revealNetworkRow(this, wifiFlickable);
                                    }

                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            if (modelData.connected && !modelData.stateChanging)
                                                modelData.disconnect();
                                            else if (!modelData.stateChanging)
                                                root.connectWifi(modelData);
                                            event.accepted = true;
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        spacing: 8

                                        Text {
                                            text: modelData.stateChanging ? "sync"
                                                : (modelData.connected ? "check_circle" : wifiSignalIcon(Math.round((modelData.signalStrength ?? 0) * 100)))
                                            color: modelData.connected ? Config.Theme.colHighlight : Config.Theme.colFg

                                            font {
                                                family: "Material Symbols Rounded"
                                                pixelSize: 19
                                            }

                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            color: Config.Theme.colFg
                                            elide: Text.ElideRight

                                            font {
                                                family: Config.Theme.fontFamily
                                                pixelSize: Config.Theme.fontSizeSmall
                                            }

                                        }

                                        Text {
                                            text: wifiSecurityIcon(modelData.security)
                                            visible: modelData.security !== WifiSecurityType.Open
                                            color: Config.Theme.colMuted
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 16
                                        }

                                        Text {
                                            text: Math.round((modelData.signalStrength ?? 0) * 100) + "%"
                                            color: Config.Theme.colMuted
                                            font.family: Config.Theme.fontFamily
                                            font.pixelSize: 10
                                        }

                                        Text {
                                            text: modelData.known ? "Saved" : ""
                                            color: Config.Theme.colMuted
                                            font.family: Config.Theme.fontFamily
                                            font.pixelSize: 9
                                        }

                                    }

                                    MouseArea {
                                        id: wifiNetworkMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: !modelData.stateChanging
                                        cursorShape: modelData.stateChanging ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected && !modelData.stateChanging)
                                                modelData.disconnect();
                                            else if (!modelData.stateChanging)
                                                root.connectWifi(modelData);

                                        }
                                    }

                                }

                            }

                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.wifiNetworks.length > root.wifiInitialVisibleCount
                        implicitHeight: 34
                        radius: 7
                        activeFocusOnTab: visible
                        Accessible.role: Accessible.Button
                        Accessible.name: root.wifiShowAll ? "Show fewer Wi-Fi networks" : "Show all Wi-Fi networks"
                        color: activeFocus
                            ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                      Config.Theme.colHighlight.b, Config.Theme.stateSelectedOpacity)
                            : (wifiShowMoreMouse.containsMouse
                                ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                          Config.Theme.colTextSec.b, Config.Theme.stateHoverOpacity)
                                : "transparent")
                        border.width: activeFocus ? 1 : 0
                        border.color: Config.Theme.colHighlight

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                    || event.key === Qt.Key_Space) {
                                root.wifiShowAll = !root.wifiShowAll;
                                if (!root.wifiShowAll)
                                    wifiFlickable.contentY = 0;
                                event.accepted = true;
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: root.wifiShowAll ? "expand_less" : "expand_more"
                                color: Config.Theme.colHighlight

                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 18
                                }

                            }

                            Text {
                                text: root.wifiShowAll ? "Show less" : "Show all networks"
                                color: Config.Theme.colFg

                                font {
                                    family: Config.Theme.fontFamily
                                    pixelSize: 11
                                }

                            }

                        }

                        MouseArea {
                            id: wifiShowMoreMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.wifiShowAll = !root.wifiShowAll;
                                if (!root.wifiShowAll)
                                    wifiFlickable.contentY = 0;

                            }
                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 7
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: "Refresh Wi-Fi networks"
                        color: activeFocus
                            ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                      Config.Theme.colHighlight.b, Config.Theme.stateSelectedOpacity)
                            : (wifiRefreshMouse.containsMouse
                                ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                          Config.Theme.colTextSec.b, Config.Theme.stateHoverOpacity)
                                : "transparent")
                        border.width: activeFocus ? 1 : 0
                        border.color: Config.Theme.colHighlight

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                    || event.key === Qt.Key_Space) {
                                root.refreshWifiNetworks();
                                event.accepted = true;
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "refresh"
                                color: Config.Theme.colHighlight

                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 17
                                }

                            }

                            Text {
                                text: "Refresh networks"
                                color: Config.Theme.colFg

                                font {
                                    family: Config.Theme.fontFamily
                                    pixelSize: 11
                                }

                            }

                        }

                        MouseArea {
                            id: wifiRefreshMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshWifiNetworks()
                        }

                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.wifiErrorText !== ""
                        text: root.wifiErrorText
                        color: Config.Theme.colRed
                        wrapMode: Text.Wrap
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 10
                    }

                    /*
                    * Wi-Fi password dialog
                    */
                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.showWifiPassword
                        implicitHeight: passwordColumn.implicitHeight + 14
                        radius: 7
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.1)

                        ColumnLayout {
                            id: passwordColumn

                            spacing: 6

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 7
                            }

                            Text {
                                text: "Password for " + root.pendingWifiSsid
                                color: Config.Theme.colFg

                                font {
                                    family: Config.Theme.fontFamily
                                    pixelSize: 11
                                    bold: true
                                }

                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Widgets.ThemedTextField {
                                    id: wifiPasswordField

                                    Layout.fillWidth: true
                                    placeholderText: "Password"
                                    echoMode: TextInput.Password
                                    horizontalTextPadding: 6
                                    text: root.wifiPassword
                                    onTextChanged: root.wifiPassword = text
                                    Keys.onReturnPressed: root.connectSecuredWifi()

                                    font {
                                        pixelSize: 11
                                    }

                                    background: Rectangle {
                                        radius: 6
                                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.14)
                                        border.width: 1
                                        border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25)
                                    }

                                }

                                Text {
                                    text: "arrow_forward"
                                    color: activeFocus || connectWifiMouse.containsMouse
                                        ? Config.Theme.colHighlight : Config.Theme.colTextSec
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Connect to Wi-Fi network " + root.pendingWifiSsid

                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            root.connectSecuredWifi();
                                            event.accepted = true;
                                        }
                                    }

                                    font {
                                        family: "Material Symbols Rounded"
                                        pixelSize: 19
                                    }

                                    MouseArea {
                                        id: connectWifiMouse
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.connectSecuredWifi()
                                    }

                                }

                            }

                            Text {
                                text: "Cancel"
                                color: cancelWifiMouse.containsMouse || activeFocus
                                    ? Config.Theme.colHighlight : Config.Theme.colMuted
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: "Cancel Wi-Fi connection"

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                            || event.key === Qt.Key_Space) {
                                        root.showWifiPassword = false;
                                        root.wifiPassword = "";
                                        root.pendingWifiSsid = "";
                                        event.accepted = true;
                                    }
                                }

                                font {
                                    family: Config.Theme.fontFamily
                                    pixelSize: 10
                                }

                                MouseArea {
                                    id: cancelWifiMouse

                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.showWifiPassword = false;
                                        root.wifiPassword = "";
                                        root.pendingWifiSsid = "";
                                    }
                                }

                            }

                        }

                    }

                }

            }

        }

        Rectangle {
            visible: root.bluetoothExpanded
            Layout.fillWidth: true
            implicitHeight: bluetoothColumn.implicitHeight + 20
            radius: 9
            color: bluetoothHover.hovered ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.18) : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.1)

            HoverHandler { id: bluetoothHover }

            ColumnLayout {
                id: bluetoothColumn

                spacing: 8

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: bluetoothHeader.implicitHeight

                    RowLayout {
                        id: bluetoothHeader
                        anchors.fill: parent

                    Text {
                        text: "bluetooth"
                        color: root.bluetoothEnabled ? Config.Theme.colHighlight : Config.Theme.colMuted

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 22
                        }

                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Bluetooth"
                            color: Config.Theme.colFg

                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: Config.Theme.fontSize
                                bold: true
                            }

                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (!root.bluetoothEnabled)
                                    return root.bluetoothBlocked ? "Blocked by the system" : "Disabled";

                                if (root.bluetoothConnected.length > 0)
                                    return root.bluetoothConnected.length + " conectado(s)";

                                return "No connected devices";
                            }
                            color: Config.Theme.colMuted
                            elide: Text.ElideRight

                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: Config.Theme.fontSizeSmall
                            }

                        }

                    }

                    Text {
                        text: root.bluetoothEnabled ? (root.bluetoothExpanded ? "expand_less" : "expand_more") : ""
                        color: Config.Theme.colMuted

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 20
                        }

                    }

                    Rectangle {
                        id: bluetoothToggle
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 22
                        radius: height / 2
                        color: root.bluetoothEnabled ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g, Config.Theme.colHighlight.b, 0.45) : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.35)

                        Rectangle {
                            x: root.bluetoothEnabled ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            radius: height / 2
                            color: root.bluetoothEnabled ? Config.Theme.colHighlight : Config.Theme.colFg
                            Behavior on x { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleBluetooth()
                        }
                    }

                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleBluetoothExpanded()
                    }
                }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.bluetoothExpanded && root.bluetoothEnabled
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.2)
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: Services.BluetoothPairingAgent.status !== ""
                        text: Services.BluetoothPairingAgent.status
                        color: Services.BluetoothPairingAgent.ready ? Config.Theme.colMuted : Config.Theme.colYellow
                        wrapMode: Text.Wrap
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 9
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: Services.BluetoothPairingAgent.promptType !== ""
                        implicitHeight: bluetoothAgentPrompt.implicitHeight + 16
                        radius: 7
                        color: Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g, Config.Theme.colHighlight.b, 0.12)

                        ColumnLayout {
                            id: bluetoothAgentPrompt
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: Services.BluetoothPairingAgent.promptText
                                color: Config.Theme.colFg
                                wrapMode: Text.Wrap
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: 10
                            }

                            Widgets.ThemedTextField {
                                id: bluetoothPinInput
                                Layout.fillWidth: true
                                visible: Services.BluetoothPairingAgent.promptType === "pin"
                                placeholderText: "PIN or code"
                                horizontalTextPadding: 6
                                inputMethodHints: Qt.ImhDigitsOnly
                                font.pixelSize: 11
                                onVisibleChanged: if (visible) forceActiveFocus()
                                Keys.onReturnPressed: {
                                    Services.BluetoothPairingAgent.answerPrompt(text);
                                    text = "";
                                }
                                background: Rectangle {
                                    radius: 6
                                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.14)
                                    border.width: 1
                                    border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25)
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: Services.BluetoothPairingAgent.promptType === "display" ? "OK" : "Decline"
                                    color: activeFocus ? Config.Theme.colFg : Config.Theme.colMuted
                                    font.underline: activeFocus
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: text === "OK" ? "Accept Bluetooth confirmation" : "Decline Bluetooth pairing"
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            Services.BluetoothPairingAgent.cancelPrompt();
                                            event.accepted = true;
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Services.BluetoothPairingAgent.cancelPrompt()
                                    }
                                }

                                Text {
                                    visible: Services.BluetoothPairingAgent.promptType === "confirm"
                                    text: "Confirm"
                                    color: Config.Theme.colHighlight
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.underline: activeFocus
                                    activeFocusOnTab: visible
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Confirm Bluetooth pairing"
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            Services.BluetoothPairingAgent.answerPrompt("yes");
                                            event.accepted = true;
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Services.BluetoothPairingAgent.answerPrompt("yes")
                                    }
                                }

                                Text {
                                    visible: Services.BluetoothPairingAgent.promptType === "pin"
                                    text: "Send"
                                    color: Config.Theme.colHighlight
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.underline: activeFocus
                                    activeFocusOnTab: visible
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Send Bluetooth code"
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            Services.BluetoothPairingAgent.answerPrompt(bluetoothPinInput.text);
                                            bluetoothPinInput.text = "";
                                            event.accepted = true;
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Services.BluetoothPairingAgent.answerPrompt(bluetoothPinInput.text);
                                            bluetoothPinInput.text = "";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.bluetoothDevices.length === 0
                        Layout.fillWidth: true
                        text: root.scanningBluetooth ? "Searching for devices…" : "No known devices"
                        color: Config.Theme.colMuted
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 8
                        bottomPadding: 8
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Flickable {
                        id: bluetoothDevicesFlickable
                        Layout.fillWidth: true
                        visible: root.bluetoothDevices.length > 0
                        implicitHeight: Math.min(bluetoothDeviceRows.implicitHeight, root.bluetoothMaxHeight)
                        contentWidth: width
                        contentHeight: bluetoothDeviceRows.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentHeight > height

                        ScrollBar.vertical: Widgets.ThemeScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        Column {
                            id: bluetoothDeviceRows
                            width: bluetoothDevicesFlickable.width
                            spacing: 2

                            Repeater {
                                model: root.bluetoothDevices

                                delegate: Rectangle {
                            id: bluetoothDeviceDelegate
                            required property var modelData

                            width: bluetoothDeviceRows.width
                            implicitHeight: 46
                            height: implicitHeight
                            radius: 7
                            activeFocusOnTab: root.bluetoothBusyAddress !== modelData.address
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.name
                                + (root.isBluetoothConnected(modelData.address)
                                   ? ", connected" : ", Bluetooth device")
                            color: activeFocus
                                ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                          Config.Theme.colHighlight.b, Config.Theme.stateSelectedOpacity)
                                : (bluetoothDeviceMouse.containsMouse
                                    ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                              Config.Theme.colTextSec.b, Config.Theme.stateHoverOpacity)
                                    : "transparent")
                            border.width: activeFocus ? 1 : 0
                            border.color: Config.Theme.colHighlight

                            onActiveFocusChanged: {
                                if (activeFocus)
                                    root.revealNetworkRow(this, bluetoothDevicesFlickable);
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                        || event.key === Qt.Key_Space) {
                                    if (root.isBluetoothConnected(modelData.address))
                                        root.disconnectBluetooth(modelData.address);
                                    else if (modelData.paired)
                                        root.connectBluetooth(modelData.address);
                                    else
                                        root.pairBluetooth(modelData.address);
                                    event.accepted = true;
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 8

                                Text {
                                    text: root.isBluetoothConnected(modelData.address) ? "bluetooth_connected" : "bluetooth"
                                    color: root.isBluetoothConnected(modelData.address) ? Config.Theme.colHighlight : Config.Theme.colFg

                                    font {
                                        family: "Material Symbols Rounded"
                                        pixelSize: 19
                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: Config.Theme.colFg
                                        elide: Text.ElideRight

                                        font {
                                            family: Config.Theme.fontFamily
                                            pixelSize: Config.Theme.fontSizeSmall
                                        }

                                    }

                                    Text {
                                        text: root.bluetoothBusyAddress === modelData.address
                                            ? (root.bluetoothBusyAction === "pair" ? "Pairing…"
                                               : root.bluetoothBusyAction === "trust" ? "Saving pairing…"
                                               : root.bluetoothBusyAction === "connect" ? "Connecting…"
                                               : root.bluetoothBusyAction === "disconnect" ? "Disconnecting…" : "Removing…")
                                            : (root.isBluetoothConnected(modelData.address) ? "Connected" : (modelData.paired ? "Paired" : "Available to pair"))
                                        color: root.isBluetoothConnected(modelData.address) || root.bluetoothBusyAddress === modelData.address
                                            ? Config.Theme.colHighlight : Config.Theme.colMuted

                                        font {
                                            family: Config.Theme.fontFamily
                                            pixelSize: 9
                                        }

                                    }

                                    Text {
                                        visible: root.bluetoothBatteryLabel(modelData.address) !== ""
                                        text: "Battery " + root.bluetoothBatteryLabel(modelData.address)
                                        color: Config.Theme.colMuted
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: 9
                                    }

                                }

                                Text {
                                    text: root.bluetoothBusyAddress === modelData.address ? "sync"
                                        : (root.isBluetoothConnected(modelData.address) ? "link_off" : "link")
                                    color: Config.Theme.colMuted

                                    font {
                                        family: "Material Symbols Rounded"
                                        pixelSize: 17
                                    }

                                }

                            }

                            MouseArea {
                                id: bluetoothDeviceMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.isBluetoothConnected(modelData.address))
                                        root.disconnectBluetooth(modelData.address);
                                    else if (modelData.paired)
                                        root.connectBluetooth(modelData.address);
                                    else
                                        root.pairBluetooth(modelData.address);
                                }
                            }

                                Text {
                                    id: bluetoothForgetIcon
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: 30
                                    text: "delete_outline"
                                    visible: modelData.paired && (bluetoothDeviceDelegate.activeFocus
                                        || bluetoothDeviceMouse.containsMouse || bluetoothForgetMouse.containsMouse
                                        || activeFocus)
                                    color: activeFocus || bluetoothForgetMouse.containsMouse
                                        ? Config.Theme.colRed : Config.Theme.colMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 17
                                    z: 2
                                    activeFocusOnTab: modelData.paired
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Forget Bluetooth device " + modelData.name
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            root.forgetBluetooth(modelData.address);
                                            event.accepted = true;
                                        }
                                    }

                                    MouseArea {
                                        id: bluetoothForgetMouse
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.forgetBluetooth(modelData.address)
                                    }
                                }

                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.pendingForgetAddress !== ""
                        implicitHeight: visible ? forgetConfirmation.implicitHeight + 16 : 0
                        radius: 7
                        color: Qt.rgba(Config.Theme.colRed.r, Config.Theme.colRed.g, Config.Theme.colRed.b, 0.14)

                        ColumnLayout {
                            id: forgetConfirmation
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: "Forget “" + root.bluetoothName(root.pendingForgetAddress) + "”?"
                                color: Config.Theme.colFg
                                wrapMode: Text.Wrap
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: 10
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Cancel"
                                    color: Config.Theme.colMuted
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Cancel removing Bluetooth device"
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            root.pendingForgetAddress = "";
                                            event.accepted = true;
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.pendingForgetAddress = ""
                                    }
                                }

                                Text {
                                    text: "Forget"
                                    color: Config.Theme.colRed
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Confirm removing Bluetooth device"
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                                || event.key === Qt.Key_Space) {
                                            root.confirmBluetoothForget();
                                            event.accepted = true;
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.confirmBluetoothForget()
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.bluetoothActionMessage !== ""
                        text: root.bluetoothActionMessage
                        color: Config.Theme.colRed
                        wrapMode: Text.Wrap
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 10
                    }

                    /*
                    * Bluetooth scan button
                    */
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 7
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: root.scanningBluetooth ? "Stop Bluetooth scan" : "Scan for Bluetooth devices"
                        color: activeFocus
                            ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                      Config.Theme.colHighlight.b, Config.Theme.stateSelectedOpacity)
                            : (bluetoothScanMouse.containsMouse
                                ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                          Config.Theme.colTextSec.b, Config.Theme.stateHoverOpacity)
                                : "transparent")
                        border.width: activeFocus ? 1 : 0
                        border.color: Config.Theme.colHighlight

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                    || event.key === Qt.Key_Space) {
                                if (root.scanningBluetooth)
                                    root.stopBluetoothScan();
                                else
                                    root.startBluetoothScan();
                                event.accepted = true;
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: root.scanningBluetooth ? "sync" : "bluetooth_searching"
                                color: Config.Theme.colHighlight

                                font {
                                    family: "Material Symbols Rounded"
                                    pixelSize: 18
                                }

                            }

                            Text {
                                text: root.scanningBluetooth ? "Scanning..." : "Scan for devices"
                                color: Config.Theme.colFg

                                font {
                                    family: Config.Theme.fontFamily
                                    pixelSize: 11
                                }

                            }

                        }

                        MouseArea {
                            id: bluetoothScanMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.scanningBluetooth)
                                    root.stopBluetoothScan();
                                else
                                    root.startBluetoothScan();
                            }
                        }

                    }

                }

            }

        }



        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Notifications"
                text: root.compactWidth ? "" : "Alerts"
                iconName: "notifications"
                selected: root.activeTab === "notifications"
                ToolTip.text: "Alerts"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "notifications"
            }

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Volume mixer"
                text: root.compactWidth ? "" : "Mixer"
                iconName: "volume_up"
                selected: root.activeTab === "volume"
                ToolTip.text: "Mixer"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "volume"
            }

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Battery info and power profile"
                text: root.compactWidth ? "" : "Battery"
                iconName: "battery_full"
                selected: root.activeTab === "battery"
                ToolTip.text: "Battery"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "battery"
            }

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                Accessible.name: "Quick shortcuts"
                text: root.compactWidth ? "" : "Shortcuts"
                iconName: "bolt"
                selected: root.activeTab === "shortcuts"
                ToolTip.text: "Shortcuts"
                ToolTip.visible: root.compactWidth && hovered
                onClicked: root.activeTab = "shortcuts"
            }

            Widgets.IconButton {
                Accessible.name: "Quickshell settings"
                iconName: "settings"
                selected: root.activeTab === "settings"
                ToolTip.text: Accessible.name
                ToolTip.visible: hovered
                onClicked: root.activeTab = "settings"
            }

            Widgets.IconButton {
                Accessible.name: Services.Notifications.doNotDisturb
                    ? "Turn off Do Not Disturb" : "Turn on Do Not Disturb"
                iconName: Services.Notifications.doNotDisturb ? "notifications_off" : "notifications_active"
                selected: Services.Notifications.doNotDisturb
                selectedIconColor: Config.Theme.colYellow
                ToolTip.text: Accessible.name
                ToolTip.visible: hovered
                onClicked: Services.Notifications.doNotDisturb = !Services.Notifications.doNotDisturb
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.activeTab === "volume" ? 1
                : root.activeTab === "battery" ? 2
                : root.activeTab === "shortcuts" ? 3
                : root.activeTab === "settings" ? 4 : 0

        NotificationHistory {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 280
            showHeader: false
            panelActive: root.visible && root.activeTab === "notifications"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: Services.Volume.effectivelyMuted ? "volume_off" : "volume_up"
                    color: Config.Theme.colHighlight
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                }

                Text {
                    Layout.fillWidth: true
                    text: "Volume"
                    color: Config.Theme.colFg
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSize
                    font.bold: true
                }

                Text {
                    text: Services.Volume.percentage + "%"
                    color: Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                }

                Widgets.IconButton {
                    id: muteVolumeButton
                    iconName: Services.Volume.effectivelyMuted ? "volume_up" : "volume_off"
                    iconSize: 18
                    buttonRadius: 7
                    implicitWidth: 28
                    implicitHeight: 28
                    Accessible.name: Services.Volume.effectivelyMuted ? "Unmute audio" : "Mute audio"
                    ToolTip.text: Accessible.name
                    ToolTip.visible: hovered
                    onClicked: Services.Volume.toggleMute()
                }

                Widgets.IconButton {
                    id: advancedAudioButton
                    iconName: "tune"
                    iconSize: 18
                    buttonRadius: 7
                    implicitWidth: 28
                    implicitHeight: 28
                    Accessible.name: "Open advanced audio options"
                    ToolTip.text: "Advanced options"
                    ToolTip.visible: hovered
                    onClicked: Quickshell.execDetached(["pavucontrol"])
                }
            }

            Widgets.ThemedSlider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: Services.Volume.volume
                Accessible.name: "Output volume"
                onMoved: Services.Volume.setVolume(value)

                Connections {
                    target: Services.Volume
                    function onVolumeChanged() {
                        volumeSlider.value = Services.Volume.volume;
                    }
                }
            }

            ScrollView {
                id: appVolumeScroll
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: root.outputAppNodes.length > 0 ? 180 : 0
                visible: root.outputAppNodes.length > 0
                clip: true
                contentWidth: availableWidth
                contentHeight: appVolumeRows.implicitHeight
                ScrollBar.vertical: Widgets.ThemeScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: appVolumeRows
                    width: appVolumeScroll.availableWidth
                    spacing: 8

                    Repeater {
                        model: ScriptModel {
                            values: root.outputAppNodes
                        }

                        delegate: RowLayout {
                            id: appVolumeRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            PwObjectTracker { objects: [appVolumeRow.modelData] }

                            Widgets.IconButton {
                                iconName: appVolumeRow.modelData.audio?.muted ? "volume_off" : "volume_up"
                                iconSize: 18
                                buttonRadius: 8
                                idleIconColor: appVolumeRow.modelData.audio?.muted
                                    ? Config.Theme.colMuted : Config.Theme.colHighlight
                                implicitWidth: 30
                                implicitHeight: 30
                                Accessible.name: "Mute " + root.audioAppName(appVolumeRow.modelData)
                                onClicked: root.toggleAppMute(appVolumeRow.modelData)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: root.audioAppName(appVolumeRow.modelData)
                                    color: Config.Theme.colFg
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                }

                                Widgets.ThemedSlider {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 1
                                    stepSize: 0.01
                                    value: appVolumeRow.modelData.audio?.volume ?? 0
                                    Accessible.name: "Volume for " + root.audioAppName(appVolumeRow.modelData)
                                    onMoved: root.setAppVolume(appVolumeRow.modelData, value)
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Services.Volume.captureApplications.length > 0
                spacing: 8

                Text {
                    text: Services.Volume.microphoneMuted ? "mic_off" : "mic"
                    color: Services.Volume.microphoneMuted ? Config.Theme.colTextSec : Config.Theme.colRed
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                }

                Text {
                    Layout.fillWidth: true
                    text: Services.Volume.captureApplications.join(", ")
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    elide: Text.ElideRight
                }

                Widgets.LabelButton {
                    text: Services.Volume.microphoneMuted ? "Unmute" : "Mute"
                    labelFontSize: Config.Theme.fontSizeSmall
                    idleTextColor: Config.Theme.colFg
                    hoverTextColor: Config.Theme.colBg
                    idleBackgroundColor: Qt.rgba(
                        Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                        Config.Theme.colTextSec.b, 0.12
                    )
                    hoverBackgroundColor: Config.Theme.colHighlight
                    cornerRadius: 7
                    Accessible.name: Services.Volume.microphoneMuted
                        ? "Unmute microphone" : "Mute microphone"
                    onClicked: Services.Volume.toggleMicrophoneMute()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Services.PrivacyIndicators.cameraApplications.length > 0
                spacing: 8

                Text {
                    text: "videocam"
                    color: Config.Theme.colRed
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                }

                Text {
                    Layout.fillWidth: true
                    text: Services.PrivacyIndicators.cameraApplications.join(", ")
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 68
                    radius: 11
                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                   Config.Theme.colTextSec.b, 0.08)
                    border.width: 1
                    border.color: outputDeviceCombo.activeFocus || outputDeviceCombo.popup.visible
                        ? Config.Theme.colHighlight
                        : Qt.rgba(Config.Theme.colBorder.r, Config.Theme.colBorder.g,
                                  Config.Theme.colBorder.b, 0.45)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 1

                        Text {
                            text: "AUDIO OUTPUT"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: 9
                            font.letterSpacing: 0.5
                        }

                        ComboBox {
                            id: outputDeviceCombo
                            Layout.fillWidth: true
                            enabled: root.outputDevices.length > 0
                            model: root.outputDevices.map(node => root.audioNodeName(node))
                            currentIndex: root.audioDeviceIndex(
                                root.outputDevices,
                                root.pipewire.preferredDefaultAudioSink,
                                root.pipewire.defaultAudioSink
                            )
                            onActivated: index => root.selectOutputDevice(index)
                            leftPadding: 9
                            rightPadding: 9
                            topPadding: 0
                            bottomPadding: 0
                            contentItem: Text {
                                leftPadding: 0
                                rightPadding: 24
                                text: outputDeviceCombo.displayText || "No output device"
                                color: Config.Theme.colFg
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 7
                                color: outputDeviceCombo.down || outputDeviceCombo.popup.visible
                                    ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                              Config.Theme.colHighlight.b, 0.15)
                                    : Qt.rgba(Config.Theme.colBg.r, Config.Theme.colBg.g,
                                              Config.Theme.colBg.b, 0.45)
                                border.width: outputDeviceCombo.activeFocus ? 1 : 0
                                border.color: Config.Theme.colHighlight
                            }
                            indicator: Text {
                                x: outputDeviceCombo.width - width - 8
                                y: (outputDeviceCombo.height - height) / 2
                                text: outputDeviceCombo.popup.visible ? "expand_less" : "expand_more"
                                color: outputDeviceCombo.popup.visible || outputDeviceCombo.activeFocus
                                    ? Config.Theme.colHighlight : Config.Theme.colTextSec
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 19
                                verticalAlignment: Text.AlignVCenter
                            }
                            delegate: ItemDelegate {
                                required property var modelData
                                required property int index
                                width: outputDeviceCombo.width - 8
                                text: modelData
                                highlighted: outputDeviceCombo.highlightedIndex === index
                                padding: 9
                                contentItem: Text {
                                    text: modelData
                                    color: parent.highlighted ? Config.Theme.colFg : Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 6
                                    color: parent.highlighted
                                        ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                                  Config.Theme.colHighlight.b, 0.2)
                                        : "transparent"
                                }
                            }
                            popup: Popup {
                                y: -height - 5
                                width: outputDeviceCombo.width
                                padding: 4
                                implicitHeight: Math.min(outputDeviceListView.contentHeight + topPadding + bottomPadding, 220)
                                background: Rectangle {
                                    radius: 10
                                    color: Config.Theme.colBg
                                    border.width: 1
                                    border.color: Config.Theme.colBorder
                                }
                                contentItem: ListView {
                                    id: outputDeviceListView
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: outputDeviceCombo.popup.visible ? outputDeviceCombo.delegateModel : null
                                    currentIndex: outputDeviceCombo.highlightedIndex
                                    ScrollIndicator.vertical: ScrollIndicator {}
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 68
                    radius: 11
                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                   Config.Theme.colTextSec.b, 0.08)
                    border.width: 1
                    border.color: inputDeviceCombo.activeFocus || inputDeviceCombo.popup.visible
                        ? Config.Theme.colHighlight
                        : Qt.rgba(Config.Theme.colBorder.r, Config.Theme.colBorder.g,
                                  Config.Theme.colBorder.b, 0.45)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 1

                        Text {
                            text: "AUDIO INPUT"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: 9
                            font.letterSpacing: 0.5
                        }

                        ComboBox {
                            id: inputDeviceCombo
                            Layout.fillWidth: true
                            enabled: root.inputDevices.length > 0
                            model: root.inputDevices.map(node => root.audioNodeName(node))
                            currentIndex: root.audioDeviceIndex(
                                root.inputDevices,
                                root.pipewire.preferredDefaultAudioSource,
                                root.pipewire.defaultAudioSource
                            )
                            onActivated: index => root.selectInputDevice(index)
                            leftPadding: 9
                            rightPadding: 9
                            topPadding: 0
                            bottomPadding: 0
                            contentItem: Text {
                                leftPadding: 0
                                rightPadding: 24
                                text: inputDeviceCombo.displayText || "No input device"
                                color: Config.Theme.colFg
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 7
                                color: inputDeviceCombo.down || inputDeviceCombo.popup.visible
                                    ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                              Config.Theme.colHighlight.b, 0.15)
                                    : Qt.rgba(Config.Theme.colBg.r, Config.Theme.colBg.g,
                                              Config.Theme.colBg.b, 0.45)
                                border.width: inputDeviceCombo.activeFocus ? 1 : 0
                                border.color: Config.Theme.colHighlight
                            }
                            indicator: Text {
                                x: inputDeviceCombo.width - width - 8
                                y: (inputDeviceCombo.height - height) / 2
                                text: inputDeviceCombo.popup.visible ? "expand_less" : "expand_more"
                                color: inputDeviceCombo.popup.visible || inputDeviceCombo.activeFocus
                                    ? Config.Theme.colHighlight : Config.Theme.colTextSec
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 19
                                verticalAlignment: Text.AlignVCenter
                            }
                            delegate: ItemDelegate {
                                required property var modelData
                                required property int index
                                width: inputDeviceCombo.width - 8
                                text: modelData
                                highlighted: inputDeviceCombo.highlightedIndex === index
                                padding: 9
                                contentItem: Text {
                                    text: modelData
                                    color: parent.highlighted ? Config.Theme.colFg : Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 6
                                    color: parent.highlighted
                                        ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                                  Config.Theme.colHighlight.b, 0.2)
                                        : "transparent"
                                }
                            }
                            popup: Popup {
                                y: -height - 5
                                width: inputDeviceCombo.width
                                padding: 4
                                implicitHeight: Math.min(inputDeviceListView.contentHeight + topPadding + bottomPadding, 220)
                                background: Rectangle {
                                    radius: 10
                                    color: Config.Theme.colBg
                                    border.width: 1
                                    border.color: Config.Theme.colBorder
                                }
                                contentItem: ListView {
                                    id: inputDeviceListView
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: inputDeviceCombo.popup.visible ? inputDeviceCombo.delegateModel : null
                                    currentIndex: inputDeviceCombo.highlightedIndex
                                    ScrollIndicator.vertical: ScrollIndicator {}
                                }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.activeTab === "battery"
            sourceComponent: Component {
                QsModules.BatteryDetails {
                    width: content.availableWidth
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Config.Theme.spaceSm

            Text {
                Layout.fillWidth: true
                text: "Quick shortcuts"
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "System and Quickshell actions. Keyboard shortcuts are defined in Hyprland."
                color: Config.Theme.colTextSec
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Config.Theme.spaceSm
                columnSpacing: Config.Theme.spaceSm

                Widgets.ActionButton {
                    Layout.fillWidth: true
                    label: "Lock screen"
                    iconName: "lock"
                    Accessible.name: label
                    onClicked: {
                        Services.Notifications.closeCenter();
                        Quickshell.execDetached(["hyprlock"]);
                    }
                }

                Widgets.ActionButton {
                    Layout.fillWidth: true
                    label: "Session"
                    iconName: "power_settings_new"
                    Accessible.name: "Open session actions"
                    onClicked: {
                        Services.Notifications.closeCenter();
                        Services.WindowControl.toggleLogout();
                    }
                }

                Widgets.ActionButton {
                    Layout.fillWidth: true
                    label: "Launcher"
                    iconName: "apps"
                    Accessible.name: "Open launcher"
                    onClicked: {
                        Services.Notifications.closeCenter();
                        Services.WindowControl.toggleLauncher();
                    }
                }

                Widgets.ActionButton {
                    Layout.fillWidth: true
                    label: "Clipboard"
                    iconName: "content_paste"
                    Accessible.name: "Open clipboard history"
                    onClicked: {
                        Services.Notifications.closeCenter();
                        Services.WindowControl.toggleClipboardHistory(Hyprland.focusedMonitor);
                    }
                }

                Widgets.ActionButton {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    label: "Configure audio"
                    iconName: "tune"
                    Accessible.name: "Open pavucontrol"
                    onClicked: {
                        Services.Notifications.closeCenter();
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Config.Theme.spaceSm

            Text {
                Layout.fillWidth: true
                text: "Settings"
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "Customize the bar, launcher and notifications. Changes are saved automatically."
                color: Config.Theme.colTextSec
                wrapMode: Text.Wrap
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
            }

            Widgets.PreferenceSwitch {
                Layout.fillWidth: true
                text: "Focused application"
                accessibleLabel: "Show the focused application in the bar"
                checked: Config.Preferences.bar.showFocusedApp
                onToggled: Config.Preferences.bar.showFocusedApp = checked
            }

            Widgets.PreferenceSwitch {
                Layout.fillWidth: true
                text: "Date in bar"
                accessibleLabel: "Show the date in the bar"
                checked: Config.Preferences.bar.showDate
                onToggled: Config.Preferences.bar.showDate = checked
            }

            Widgets.PreferenceSwitch {
                Layout.fillWidth: true
                text: "System tray"
                accessibleLabel: "Show system tray icons in the bar"
                checked: Config.Preferences.bar.showTray
                onToggled: Config.Preferences.bar.showTray = checked
            }

            Widgets.PreferenceSwitch {
                Layout.fillWidth: true
                text: "Device controls"
                accessibleLabel: "Show volume, battery, Wi-Fi, Bluetooth and Do Not Disturb in the bar"
                checked: Config.Preferences.bar.showDeviceIndicators
                onToggled: Config.Preferences.bar.showDeviceIndicators = checked
            }

            Widgets.PreferenceSwitch {
                Layout.fillWidth: true
                text: "System status"
                accessibleLabel: "Show CPU and memory indicators in the bar"
                checked: Config.Preferences.bar.showSystemStatus
                onToggled: Config.Preferences.bar.showSystemStatus = checked
            }

            Widgets.PreferenceSwitch {
                Layout.fillWidth: true
                text: "Media"
                accessibleLabel: "Show the media player in the bar"
                checked: Config.Preferences.bar.showMedia
                onToggled: Config.Preferences.bar.showMedia = checked
            }

            Widgets.PreferenceSwitch {
                Layout.fillWidth: true
                text: "Prioritize used apps"
                accessibleLabel: "Prioritize recently used applications when launcher results tie"
                checked: Config.Preferences.launcher.prioritizeUsage
                onToggled: Config.Preferences.launcher.prioritizeUsage = checked
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.Theme.spaceSm

                Text {
                    Layout.fillWidth: true
                    text: "Default notification duration"
                    color: Config.Theme.colFg
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSize
                }

                Text {
                    text: Config.Preferences.notifications.defaultTimeoutSeconds + " s"
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                }
            }

            Widgets.ThemedSlider {
                Layout.fillWidth: true
                from: 1
                to: 10
                stepSize: 1
                value: Config.Preferences.notifications.defaultTimeoutSeconds
                Accessible.name: "Default notification duration in seconds"
                onMoved: Config.Preferences.notifications.defaultTimeoutSeconds = Math.round(value)
            }
        }

        }

        }
    }

    SidebarCalendar {
        id: sidebarCalendar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 16
        }
        height: implicitHeight
        z: 1
        active: root.visible
        compact: root.compactLayout
        collapsed: Services.Notifications.centerCalendarCollapsed
        onCollapseToggled: collapsed => Services.Notifications.centerCalendarCollapsed = collapsed
    }

}
