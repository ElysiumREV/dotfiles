import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Config
import "../services" as Services

PanelWindow {
    id: root

    required property var positionProvider
    property real popupX: 0
    property bool wifiEnabled: false
    property string wifiName: "Desconectado"
    property bool bluetoothEnabled: false
    property string pendingAction: ""

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

    function openMenu() {
        pendingAction = "";
        popupX = positionProvider(implicitWidth).x;
        refresh();
        visible = true;
    }

    function refresh() {
        wifiStatusProcess.running = true;
        wifiNameProcess.running = true;
        bluetoothStatusProcess.running = true;
        Services.Brightness.readBrightness();
        Services.PowerProfiles.updateActiveProfile();
    }

    function toggleWifi() {
        wifiToggleProcess.exec(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
    }

    function toggleBluetooth() {
        bluetoothToggleProcess.exec([
            "bluetoothctl", "power", bluetoothEnabled ? "off" : "on"
        ]);
    }

    function profileLabel(profile) {
        switch (profile) {
        case "performance": return "Desempenho";
        case "power-saver": return "Economia";
        default: return "Balanceado";
        }
    }

    function profileIcon(profile) {
        switch (profile) {
        case "performance": return "speed";
        case "power-saver": return "energy_savings_leaf";
        default: return "balance";
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

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "-t", "-f", "WIFI", "general"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: wifiNameProcess
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1 == \"yes\" { print $2; exit }'"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiName = text.trim() || "Desconectado"
        }
    }

    Process {
        id: wifiToggleProcess
        onExited: wifiStatusProcess.running = true
    }

    Process {
        id: bluetoothStatusProcess
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothEnabled = /Powered:\s+yes/.test(text)
        }
    }

    Process {
        id: bluetoothToggleProcess
        onExited: bluetoothStatusProcess.running = true
    }

    Process { id: sessionActionProcess }

    Rectangle {
        anchors.fill: parent
        color: Config.Theme.colBg
        radius: 12
        border.width: 1
        border.color: Qt.rgba(
            Config.Theme.colTextSec.r,
            Config.Theme.colTextSec.g,
            Config.Theme.colTextSec.b,
            0.25
        )
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
        }
        spacing: 12

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 58
                radius: 9
                color: wifiMouse.containsMouse
                       ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.18)
                       : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.10)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: root.wifiEnabled ? "wifi" : "wifi_off"
                        color: root.wifiEnabled ? Config.Theme.colHighlight : Config.Theme.colMuted
                        font { family: "Material Symbols Rounded"; pixelSize: 22 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "Wi‑Fi"
                            color: Config.Theme.colFg
                            font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSize; bold: true }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.wifiEnabled ? root.wifiName : "Desativado"
                            color: Config.Theme.colMuted
                            font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall }
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: wifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleWifi()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 58
                radius: 9
                color: bluetoothMouse.containsMouse
                       ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.18)
                       : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.10)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: "bluetooth"
                        color: root.bluetoothEnabled ? Config.Theme.colHighlight : Config.Theme.colMuted
                        font { family: "Material Symbols Rounded"; pixelSize: 22 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "Bluetooth"
                            color: Config.Theme.colFg
                            font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSize; bold: true }
                        }
                        Text {
                            text: root.bluetoothEnabled ? "Ativado" : "Desativado"
                            color: Config.Theme.colMuted
                            font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall }
                        }
                    }
                }

                MouseArea {
                    id: bluetoothMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleBluetooth()
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
                    font { family: "Material Symbols Rounded"; pixelSize: 20 }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Brilho"
                    color: Config.Theme.colFg
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSize; bold: true }
                }
                Text {
                    text: Services.Brightness.percentage + "%"
                    color: Config.Theme.colMuted
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall }
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
                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.20)

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
                    onPressed: mouse => Services.Brightness.setBrightness(mouse.x / width)
                    onPositionChanged: mouse => {
                        if (pressed)
                            Services.Brightness.setBrightness(mouse.x / width)
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
                model: [
                    { name: "Bloquear", icon: "lock", action: "lock" },
                    { name: "Sair", icon: "logout", action: "logout" },
                    { name: "Reiniciar", icon: "restart_alt", action: "reboot" },
                    { name: "Desligar", icon: "power_settings_new", action: "shutdown" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 8
                    color: actionMouse.containsMouse
                           ? Qt.rgba(Config.Theme.colRed.r, Config.Theme.colRed.g, Config.Theme.colRed.b, 0.25)
                           : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.10)

                    Column {
                        anchors.centerIn: parent
                        spacing: 1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            color: Config.Theme.colFg
                            font { family: "Material Symbols Rounded"; pixelSize: 20 }
                        }
                        Text {
                            text: modelData.name
                            color: Config.Theme.colFg
                            font { family: Config.Theme.fontFamily; pixelSize: 10 }
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
                    text: root.pendingAction === "lock"
                          ? "Bloquear a sessão?"
                          : "Confirmar " + ({ logout: "saída", reboot: "reinício", shutdown: "desligamento" }[root.pendingAction]) + "?"
                    color: Config.Theme.colFg
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall; bold: true }
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Cancelar"
                        color: confirmCancelMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colFg
                        font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall }
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
                        font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall; bold: true }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.confirmAction()
                        }
                    }
                }
            }
        }
    }
}
