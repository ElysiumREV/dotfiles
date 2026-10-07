import ".." as Config
import "../services" as Services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var positionProvider
    property real popupX: 0
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
    readonly property string wifiName: activeWifiNetwork?.name ?? "Desconectado"
    property var pendingWifiNetwork: null
    property string wifiErrorText: ""
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: bluetoothAdapter?.enabled ?? false
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
    property string pendingAction: ""
    property bool wifiShowAll: false
    property int wifiInitialVisibleCount: 6
    property int wifiMaxHeight: 300

    function openMenu() {
        pendingAction = "";
        popupX = positionProvider(implicitWidth).x;
        wifiExpanded = false;
        bluetoothExpanded = false;
        wifiShowAll = false;
        showWifiPassword = false;
        wifiPassword = "";
        refresh();
        visible = true;
    }

    onVisibleChanged: {
        if (!visible) {
            wifiScanStopTimer.stop();
            if (wifiDevice)
                wifiDevice.scannerEnabled = false;
            stopBluetoothScan();
            if (bluetoothBusyAction !== "pair" && bluetoothBusyAction !== "trust"
                    && Services.BluetoothPairingAgent.promptType === "")
                Services.BluetoothPairingAgent.release();
        }
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
        root.bluetoothDevices = result;
    }

    function toggleWifi() {
        wifiErrorText = "";
        if (!wifiHardwareEnabled) {
            wifiErrorText = "O adaptador Wi-Fi está bloqueado pelo sistema.";
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
            bluetoothScanTimer.stop();
            if (bluetoothAdapter)
                bluetoothAdapter.discovering = false;
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

    function toggleBluetoothExpanded() {
        if (!bluetoothEnabled)
            return ;
        bluetoothExpanded = !bluetoothExpanded;
        if (bluetoothExpanded) {
            wifiExpanded = false;
            Services.BluetoothPairingAgent.ensureStarted();
            bluetoothDevicesProcess.running = true;
            bluetoothKnownDevicesProcess.running = true;
            bluetoothConnectedProcess.running = true;
        } else if (bluetoothBusyAction !== "pair" && bluetoothBusyAction !== "trust"
                && Services.BluetoothPairingAgent.promptType === "")
            Services.BluetoothPairingAgent.release();
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
        wifiErrorText = "Falha ao conectar em " + network.name + ": " + ConnectionFailReason.toString(reason);
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
            wifiErrorText = "Esta rede exige credenciais avançadas que ainda não são suportadas pelo menu.";
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
                ? "Não foi possível parear. Confira se o dispositivo está em modo de pareamento."
                : action === "connect" ? "Não foi possível conectar ao dispositivo."
                : action === "disconnect" ? "Não foi possível desconectar o dispositivo."
                : "Não foi possível remover o dispositivo pareado.";
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
        if (!bluetoothKnownDevicesProcess.running)
            bluetoothKnownDevicesProcess.running = true;
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

    function profileLabel(profile) {
        switch (profile) {
        case "performance":
            return "Desempenho";
        case "power-saver":
            return "Economia";
        default:
            return "Balanceado";
        }
    }

    function profileIcon(profile) {
        switch (profile) {
        case "performance":
            return "speed";
        case "power-saver":
            return "energy_savings_leaf";
        default:
            return "balance";
        }
    }

    function requestAction(action) {
        pendingAction = action;
    }

    function confirmAction() {
        const action = pendingAction;
        pendingAction = "";
        if (action === "lock")
            sessionActionProcess.exec(["hyprlock"]);
        else if (action === "logout")
            sessionActionProcess.exec(["hyprshutdown", "--post-cmd", "hyprctl dispatch hl.dsp.exit()"]);
        else if (action === "reboot")
            sessionActionProcess.exec(["hyprshutdown", "-t", "Restarting...", "--post-cmd", "reboot"]);
        else if (action === "shutdown")
            sessionActionProcess.exec(["hyprshutdown", "-t", "Shutting down...", "--post-cmd", "shutdown -P 0"]);
    }

    color: "transparent"
    visible: false
    focusable: true
    implicitWidth: 360
    implicitHeight: content.implicitHeight + 32
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        left: root.popupX
    }

    PopupDismissBehavior { popup: root }

    Timer {
        interval: 15000
        repeat: true
        running: root.visible
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
                root.bluetoothActionMessage = Services.BluetoothPairingAgent.status || "Agente de pareamento indisponível.";
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
        interval: 1500
        repeat: true
        running: root.visible && root.scanningBluetooth
        onTriggered: {
            if (!bluetoothKnownDevicesProcess.running)
                bluetoothKnownDevicesProcess.running = true;
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
                root.bluetoothActionMessage = "Pareado, mas não foi possível marcar como confiável.";
            root.refreshBluetoothDevices();
            if (!root.visible && Services.BluetoothPairingAgent.promptType === "")
                Services.BluetoothPairingAgent.release();
        }
    }

    Process {
        id: bluetoothForgetProcess
        onExited: (code) => root.completeBluetoothAction("forget", root.bluetoothBusyAddress, code)
    }

    Process {
        id: sessionActionProcess
    }

    Rectangle {
        anchors.fill: parent
        color: Config.Theme.colBg
        radius: 12
        border.width: 1
        border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25)
    }

    ColumnLayout {
        /*
        * ==============================================================
        * WI-FI
        * ==============================================================
        */
        /*
        * ==============================================================
        * BLUETOOTH
        * ==============================================================
        */
        /*
        * ==============================================================
        * BRIGHTNESS
        * ==============================================================
        */
        /*
        * ==============================================================
        * SESSION ACTIONS
        * ==============================================================
        */

        id: content

        spacing: 12

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: ""
                color: Config.Theme.colHighlight

                font {
                    family: Config.Theme.fontFamily
                    pixelSize: 24
                }

            }

            Text {
                Layout.fillWidth: true
                text: "Configurações rápidas"
                color: Config.Theme.colFg

                font {
                    family: Config.Theme.fontFamily
                    pixelSize: Config.Theme.fontSizeLarge
                    bold: true
                }

            }

            Text {
                text: "close"
                color: closeMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colMuted

                font {
                    family: "Material Symbols Rounded"
                    pixelSize: 20
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.visible = false
                }

            }

        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25)
        }

        Rectangle {
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
                            text: root.wifiEnabled ? root.wifiName : "Desativado"
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

                        Text {
                            anchors.centerIn: parent
                            visible: root.wifiNetworks.length === 0
                            text: root.wifiDevice?.scannerEnabled ? "Buscando redes…" : "Nenhuma rede encontrada"
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
                                    color: wifiNetworkMouse.containsMouse ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.16) : "transparent"

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
                                            text: modelData.known ? "Salva" : ""
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
                        color: wifiShowMoreMouse.containsMouse ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.16) : "transparent"

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
                                text: root.wifiShowAll ? "Mostrar menos" : "Mostrar todas as redes"
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
                        color: wifiRefreshMouse.containsMouse ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.16) : "transparent"

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
                                text: "Atualizar redes"
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
                                text: "Senha de " + root.pendingWifiSsid
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

                                TextField {
                                    id: wifiPasswordField

                                    Layout.fillWidth: true
                                    placeholderText: "Senha"
                                    echoMode: TextInput.Password
                                    text: root.wifiPassword
                                    color: Config.Theme.colFg
                                    onTextChanged: root.wifiPassword = text
                                    Keys.onReturnPressed: root.connectSecuredWifi()

                                    font {
                                        family: Config.Theme.fontFamily
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
                                    color: Config.Theme.colHighlight

                                    font {
                                        family: "Material Symbols Rounded"
                                        pixelSize: 19
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.connectSecuredWifi()
                                    }

                                }

                            }

                            Text {
                                text: "Cancelar"
                                color: cancelWifiMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colMuted

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
                                    return "Desativado";

                                if (root.bluetoothConnected.length > 0)
                                    return root.bluetoothConnected.length + " conectado(s)";

                                return "Nenhum dispositivo conectado";
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

                            TextField {
                                id: bluetoothPinInput
                                Layout.fillWidth: true
                                visible: Services.BluetoothPairingAgent.promptType === "pin"
                                placeholderText: "PIN ou código"
                                inputMethodHints: Qt.ImhDigitsOnly
                                color: Config.Theme.colFg
                                font.family: Config.Theme.fontFamily
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
                                    text: Services.BluetoothPairingAgent.promptType === "display" ? "OK" : "Recusar"
                                    color: Config.Theme.colMuted
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Services.BluetoothPairingAgent.cancelPrompt()
                                    }
                                }

                                Text {
                                    visible: Services.BluetoothPairingAgent.promptType === "confirm"
                                    text: "Confirmar"
                                    color: Config.Theme.colHighlight
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Services.BluetoothPairingAgent.answerPrompt("yes")
                                    }
                                }

                                Text {
                                    visible: Services.BluetoothPairingAgent.promptType === "pin"
                                    text: "Enviar"
                                    color: Config.Theme.colHighlight
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
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
                        text: root.scanningBluetooth ? "Procurando dispositivos…" : "Nenhum dispositivo conhecido"
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
                        implicitHeight: Math.min(bluetoothDeviceRows.implicitHeight, 220)
                        contentWidth: width
                        contentHeight: bluetoothDeviceRows.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentHeight > height

                        Column {
                            id: bluetoothDeviceRows
                            width: bluetoothDevicesFlickable.width
                            spacing: 2

                            Repeater {
                                model: root.bluetoothDevices

                                delegate: Rectangle {
                            required property var modelData

                            width: bluetoothDeviceRows.width
                            implicitHeight: 46
                            radius: 7
                            color: bluetoothDeviceMouse.containsMouse ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.16) : "transparent"

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
                                            ? (root.bluetoothBusyAction === "pair" ? "Pareando…"
                                               : root.bluetoothBusyAction === "trust" ? "Salvando pareamento…"
                                               : root.bluetoothBusyAction === "connect" ? "Conectando…"
                                               : root.bluetoothBusyAction === "disconnect" ? "Desconectando…" : "Removendo…")
                                            : (root.isBluetoothConnected(modelData.address) ? "Conectado" : (modelData.paired ? "Pareado" : "Disponível para parear"))
                                        color: root.isBluetoothConnected(modelData.address) || root.bluetoothBusyAddress === modelData.address
                                            ? Config.Theme.colHighlight : Config.Theme.colMuted

                                        font {
                                            family: Config.Theme.fontFamily
                                            pixelSize: 9
                                        }

                                    }

                                    Text {
                                        visible: root.bluetoothBatteryLabel(modelData.address) !== ""
                                        text: "Bateria " + root.bluetoothBatteryLabel(modelData.address)
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
                                    visible: modelData.paired && (bluetoothDeviceMouse.containsMouse || bluetoothForgetMouse.containsMouse)
                                    color: bluetoothForgetMouse.containsMouse ? Config.Theme.colRed : Config.Theme.colMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 17
                                    z: 2

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
                                text: "Esquecer “" + root.bluetoothName(root.pendingForgetAddress) + "”?"
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
                                    text: "Cancelar"
                                    color: Config.Theme.colMuted
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.pendingForgetAddress = ""
                                    }
                                }

                                Text {
                                    text: "Esquecer"
                                    color: Config.Theme.colRed
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
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
                        color: bluetoothScanMouse.containsMouse ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.16) : "transparent"

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
                                text: root.scanningBluetooth ? "Procurando dispositivos..." : "Procurar dispositivos"
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
                    text: "Brilho"
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
                Layout.fillWidth: true
                implicitHeight: 16

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

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [{
                    "name": "Bloquear",
                    "icon": "lock",
                    "action": "lock"
                }, {
                    "name": "Sair",
                    "icon": "logout",
                    "action": "logout"
                }, {
                    "name": "Reiniciar",
                    "icon": "restart_alt",
                    "action": "reboot"
                }, {
                    "name": "Desligar",
                    "icon": "power_settings_new",
                    "action": "shutdown"
                }]

                delegate: Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 8
                    color: actionMouse.containsMouse ? Qt.rgba(Config.Theme.colRed.r, Config.Theme.colRed.g, Config.Theme.colRed.b, 0.25) : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.1)

                    Column {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            color: Config.Theme.colFg

                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 20
                            }

                        }

                        Text {
                            text: modelData.name
                            color: Config.Theme.colFg

                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: 10
                            }

                        }

                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.requestAction(modelData.action)
                    }

                }

            }

        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.pendingAction !== ""
            implicitHeight: visible ? 74 : 0
            radius: 8
            color: Qt.rgba(Config.Theme.colRed.r, Config.Theme.colRed.g, Config.Theme.colRed.b, 0.16)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: root.pendingAction === "lock" ? "Bloquear a sessão?" : "Confirmar " + ({
                        "logout": "saída",
                        "reboot": "reinício",
                        "shutdown": "desligamento"
                    }[root.pendingAction]) + "?"
                    color: Config.Theme.colFg
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        family: Config.Theme.fontFamily
                        pixelSize: Config.Theme.fontSizeSmall
                        bold: true
                    }

                }

                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Cancelar"
                        color: confirmCancelMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colFg

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeSmall
                        }

                        MouseArea {
                            id: confirmCancelMouse

                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pendingAction = ""
                        }

                    }

                    Text {
                        text: "Confirmar"
                        color: Config.Theme.colRed

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: Config.Theme.fontSizeSmall
                            bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.confirmAction()
                        }

                    }

                }

            }

        }

    }

}
