import ".." as Config
import "../services" as Services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var positionProvider
    property real popupX: 0
    property bool wifiEnabled: false
    property string wifiName: "Desconectado"
    property var wifiNetworks: []
    property bool bluetoothEnabled: false
    property var bluetoothDevices: []
    property var bluetoothConnected: []
    property bool wifiExpanded: false
    property bool bluetoothExpanded: false
    property bool scanningBluetooth: false
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

    function refresh() {
        wifiStatusProcess.running = true;
        wifiNameProcess.running = true;
        bluetoothStatusProcess.running = true;
        if (wifiEnabled)
            wifiScanProcess.running = true;

        if (bluetoothEnabled) {
            bluetoothDevicesProcess.running = true;
            bluetoothConnectedProcess.running = true;
        }
        Services.Brightness.readBrightness();
    }

    function toggleWifi() {
        wifiToggleProcess.exec(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
    }

    function toggleBluetooth() {
        bluetoothToggleProcess.exec(["bluetoothctl", "power", bluetoothEnabled ? "off" : "on"]);
    }

    function toggleWifiExpanded() {
        if (!wifiEnabled) {
            toggleWifi();
            return ;
        }
        wifiExpanded = !wifiExpanded;
        if (wifiExpanded) {
            bluetoothExpanded = false;
            wifiScanProcess.running = true;
        }
    }

    function toggleBluetoothExpanded() {
        if (!bluetoothEnabled) {
            toggleBluetooth();
            return ;
        }
        bluetoothExpanded = !bluetoothExpanded;
        if (bluetoothExpanded) {
            wifiExpanded = false;
            bluetoothDevicesProcess.running = true;
            bluetoothConnectedProcess.running = true;
        }
    }

    function connectWifi(ssid, secured) {
        if (secured) {
            pendingWifiSsid = ssid;
            wifiPassword = "";
            showWifiPassword = true;
            return ;
        }
        wifiConnectProcess.exec(["nmcli", "device", "wifi", "connect", ssid]);
    }

    function connectSecuredWifi() {
        if (pendingWifiSsid === "" || wifiPassword === "")
            return ;

        wifiConnectProcess.exec(["nmcli", "device", "wifi", "connect", pendingWifiSsid, "password", wifiPassword]);
        showWifiPassword = false;
        wifiPassword = "";
        pendingWifiSsid = "";
    }

    function connectBluetooth(address) {
        bluetoothConnectProcess.exec(["bluetoothctl", "connect", address]);
    }

    function disconnectBluetooth(address) {
        bluetoothDisconnectProcess.exec(["bluetoothctl", "disconnect", address]);
    }

    function startBluetoothScan() {
        if (!bluetoothEnabled)
            return ;

        scanningBluetooth = true;
        bluetoothScanOnProcess.running = true;
        bluetoothDevicesProcess.running = true;
        bluetoothScanTimer.restart();
    }

    function stopBluetoothScan() {
        scanningBluetooth = false;
        bluetoothScanOffProcess.running = true;
        bluetoothDevicesProcess.running = true;
    }

    function isBluetoothConnected(address) {
        return bluetoothConnected.indexOf(address) !== -1;
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
        return security !== "" ? "lock" : "lock_open";
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
            sessionActionProcess.exec(["hyprctl", "dispatch", "exit"]);
        else if (action === "reboot")
            sessionActionProcess.exec(["systemctl", "reboot"]);
        else if (action === "shutdown")
            sessionActionProcess.exec(["systemctl", "poweroff"]);
    }

    color: "transparent"
    visible: false
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

    Timer {
        interval: 5000
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

    Process {
        id: wifiStatusProcess

        command: ["nmcli", "-t", "-f", "WIFI", "general"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
                if (!root.wifiEnabled) {
                    root.wifiNetworks = [];
                    root.wifiExpanded = false;
                }
            }
        }

    }

    Process {
        id: wifiNameProcess

        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1 == \"yes\" { print $2; exit }'"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiName = text.trim() || "Desconectado";
            }
        }

    }

    Process {
        id: wifiScanProcess

        command: ["nmcli", "--terse", "--fields", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]

        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                const lines = text.trim().split("\n");
                for (let line of lines) {
                    if (!line.trim())
                        continue;

                    /*
                    * nmcli terse mode escapes ':' as '\:'.
                    * SSIDs can therefore safely contain colons.
                    */
                    const fields = [];
                    let current = "";
                    let escaped = false;
                    for (let i = 0; i < line.length; i++) {
                        const ch = line[i];
                        if (escaped) {
                            current += ch;
                            escaped = false;
                        } else if (ch === "\\") {
                            escaped = true;
                        } else if (ch === ":") {
                            fields.push(current);
                            current = "";
                        } else {
                            current += ch;
                        }
                    }
                    fields.push(current);
                    if (fields.length < 4)
                        continue;

                    const active = fields[0] === "yes";
                    const ssid = fields[1];
                    const signal = parseInt(fields[2]) || 0;
                    const security = fields[3];
                    if (ssid === "")
                        continue;

                    let duplicate = false;
                    for (let existing of result) {
                        if (existing.ssid === ssid) {
                            duplicate = true;
                            /*
                            * Keep the stronger access point if multiple
                            * APs advertise the same SSID.
                            */
                            if (signal > existing.signal) {
                                existing.signal = signal;
                                existing.active = active;
                            }
                            break;
                        }
                    }
                    if (!duplicate)
                        result.push({
                            "ssid": ssid,
                            "signal": signal,
                            "security": security,
                            "active": active
                        });

                }
                result.sort(function(a, b) {
                    if (a.active !== b.active)
                        return a.active ? -1 : 1;

                    return b.signal - a.signal;
                });
                root.wifiNetworks = result;
            }
        }

    }

    Process {
        id: wifiToggleProcess

        onExited: {
            wifiStatusProcess.running = true;
            wifiNameProcess.running = true;
            if (root.wifiEnabled)
                wifiScanProcess.running = true;

        }
    }

    Process {
        id: wifiConnectProcess

        onExited: {
            wifiStatusProcess.running = true;
            wifiNameProcess.running = true;
            wifiScanProcess.running = true;
        }
    }

    Process {
        id: bluetoothStatusProcess

        command: ["bluetoothctl", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.bluetoothEnabled = /Powered:\s+yes/.test(text);
                if (!root.bluetoothEnabled) {
                    root.bluetoothDevices = [];
                    root.bluetoothConnected = [];
                    root.bluetoothExpanded = false;
                    root.scanningBluetooth = false;
                }
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
                root.bluetoothDevices = result;
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
        id: bluetoothToggleProcess

        onExited: {
            bluetoothStatusProcess.running = true;
            if (root.bluetoothEnabled) {
                bluetoothDevicesProcess.running = true;
                bluetoothConnectedProcess.running = true;
            }
        }
    }

    Process {
        id: bluetoothConnectProcess

        onExited: {
            bluetoothConnectedProcess.running = true;
        }
    }

    Process {
        id: bluetoothDisconnectProcess

        onExited: {
            bluetoothConnectedProcess.running = true;
        }
    }

    Process {
        id: bluetoothScanOnProcess

        command: ["bluetoothctl", "scan", "on"]
    }

    Process {
        id: bluetoothScanOffProcess

        command: ["bluetoothctl", "scan", "off"]
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
            color: wifiMouse.containsMouse ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.18) : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.1)

            ColumnLayout {
                id: wifiColumn

                spacing: 8

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }

                RowLayout {
                    id: wifiHeader

                    Layout.fillWidth: true

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
                        text: root.wifiEnabled ? (root.wifiExpanded ? "expand_less" : "expand_more") : "power_settings_new"
                        color: Config.Theme.colMuted

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 20
                        }

                    }

                    RowLayout {
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.centerIn: parent
                                text: "Wi-Fi"
                            }

                            MouseArea {
                                id: wifiMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleWifiExpanded()
                            }

                        }

                    }

                }

                /*
                * Wi-Fi network list
                */
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.wifiExpanded && root.wifiEnabled
                    spacing: 4

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
                                            text: modelData.active ? "check" : wifiSignalIcon(modelData.signal)
                                            color: modelData.active ? Config.Theme.colHighlight : Config.Theme.colFg

                                            font {
                                                family: "Material Symbols Rounded"
                                                pixelSize: 19
                                            }

                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.ssid
                                            color: Config.Theme.colFg
                                            elide: Text.ElideRight

                                            font {
                                                family: Config.Theme.fontFamily
                                                pixelSize: Config.Theme.fontSizeSmall
                                            }

                                        }

                                        Text {
                                            text: wifiSecurityIcon(modelData.security)
                                            visible: modelData.security !== ""
                                            color: Config.Theme.colMuted

                                            font {
                                                family: "Material Symbols Rounded"
                                                pixelSize: 16
                                            }

                                        }

                                        Text {
                                            text: modelData.signal + "%"
                                            color: Config.Theme.colMuted

                                            font {
                                                family: Config.Theme.fontFamily
                                                pixelSize: 10
                                            }

                                        }

                                    }

                                    MouseArea {
                                        id: wifiNetworkMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!modelData.active)
                                                root.connectWifi(modelData.ssid, modelData.security !== "");

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
                            onClicked: wifiScanProcess.running = true
                        }

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
            color: bluetoothMouse.containsMouse ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.18) : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.1)

            ColumnLayout {
                id: bluetoothColumn

                spacing: 8

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }

                RowLayout {
                    id: bluetoothHeader

                    Layout.fillWidth: true

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
                        text: root.bluetoothEnabled ? (root.bluetoothExpanded ? "expand_less" : "expand_more") : "power_settings_new"
                        color: Config.Theme.colMuted

                        font {
                            family: "Material Symbols Rounded"
                            pixelSize: 20
                        }

                    }

                    RowLayout {
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.centerIn: parent
                                text: "Wi-Fi"
                            }

                            MouseArea {
                                id: bluetoothMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleBluetoothExpanded()
                            }

                        }

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
                        visible: root.bluetoothDevices.length === 0
                        Layout.fillWidth: true
                        text: "Nenhum dispositivo pareado"
                        color: Config.Theme.colMuted
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 8
                        bottomPadding: 8

                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: 11
                        }

                    }

                    Repeater {
                        model: root.bluetoothDevices

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
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
                                        text: root.isBluetoothConnected(modelData.address) ? "Conectado" : "Pareado"
                                        color: root.isBluetoothConnected(modelData.address) ? Config.Theme.colHighlight : Config.Theme.colMuted

                                        font {
                                            family: Config.Theme.fontFamily
                                            pixelSize: 9
                                        }

                                    }

                                }

                                Text {
                                    text: root.isBluetoothConnected(modelData.address) ? "link_off" : "link"
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
                                    else
                                        root.connectBluetooth(modelData.address);
                                }
                            }

                        }

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
