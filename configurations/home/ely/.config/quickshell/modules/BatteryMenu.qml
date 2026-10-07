import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import ".." as Config
import "../services" as Services
import "../services/BatteryRules.js" as BatteryRules

PanelWindow {
    id: root

    required property var positionProvider
    required property var targetScreen
    property real popupRight: 16
    property int chargeCycles: -1
    property bool chargeCyclesLoaded: false
    property bool batteryHealthLoaded: false
    property string pendingAction: ""
    property string batteryCapacity: "—"
    property string batteryHealth: "—"
    property string batteryChangeRate: "—"
    property string batteryStatusLabel: "Sem bateria"
    property real batteryPercentage: 0
    property bool batteryPresent: false
    readonly property string batteryIconName: batteryPresent
        ? BatteryRules.iconName(batteryPercentage, isCharging)
        : "battery_alert"

    // --- Omarchy-inspired Properties ---
    property int phraseIndex: 0
    readonly property bool isCharging: {
        const s = UPower.displayDevice?.state
        return s === UPowerDeviceState.Charging || s === UPowerDeviceState.PendingCharge
    }
    readonly property bool isFullyCharged: UPower.displayDevice?.state === UPowerDeviceState.FullyCharged
    readonly property bool isDischarging: {
        const s = UPower.displayDevice?.state
        return s === UPowerDeviceState.Discharging || s === UPowerDeviceState.PendingDischarge
    }
    readonly property real estimatedTimeSeconds: {
        const battery = UPower.displayDevice;
        if (!batteryPresent)
            return 0;
        return isCharging ? (battery.timeToFull ?? 0)
            : (isDischarging ? (battery.timeToEmpty ?? 0) : 0);
    }
    readonly property string estimatedTime: formatDuration(estimatedTimeSeconds)

    // --- Lógica de Bateria Fraca/Crítica do seu módulo ---
    readonly property bool isPluggedIn: isCharging || isFullyCharged
    readonly property bool isLow: BatteryRules.isLow(batteryPercentage, isPluggedIn)
    readonly property bool isCritical: BatteryRules.isCritical(batteryPercentage, isPluggedIn)

    readonly property var chargingPhrases: [
        "Injetando elétrons",
        "Armazenando energia",
        "Puxando watts",
        "Enchendo o tanque"
    ]
    readonly property var dischargingPhrases: [
        "Consumindo bateria",
        "Gastando energia",
        "Drenando watts",
        "Usando reservas"
    ]
    readonly property var activePhrases: isFullyCharged ? [] : (isCharging ? chargingPhrases : (isDischarging ? dischargingPhrases : []))
    readonly property bool rotatingPhrases: activePhrases.length > 0

    // -----------------------------------

    color: "transparent"
    visible: false
    screen: targetScreen
    implicitWidth: 380
    implicitHeight: content.implicitHeight + 32
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        right: root.popupRight
    }

    PopupDismissBehavior { popup: root }

    function openMenu() {
        popupRight = positionProvider(implicitWidth).right;
        refresh(true);
        visible = true;
    }

    function formatDuration(seconds) {
        const minutes = Math.round(Number(seconds) / 60);
        if (!Number.isFinite(minutes) || minutes <= 0)
            return "—";
        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;
        return hours > 0 ? hours + " h " + remainingMinutes + " min" : minutes + " min";
    }

    function requestAction(action) {
        pendingAction = action;
    }

    function confirmAction() {
        const action = pendingAction;
        pendingAction = "";

        if (action === "lock") sessionActionProcess.exec(["hyprlock"]);
        else if (action === "logout") sessionActionProcess.exec(["hyprctl", "dispatch", "exit"]);
        else if (action === "reboot") sessionActionProcess.exec(["systemctl", "reboot"]);
        else if (action === "shutdown") sessionActionProcess.exec(["systemctl", "poweroff"]);
    }

    function refresh(retryChargeCycles) {
        const b = UPower.displayDevice;
        if (b && b.isPresent) {
            batteryPresent = true;
            batteryCapacity = Number.isFinite(b.energyCapacity) && b.energyCapacity > 0
                ? b.energyCapacity.toFixed(0) : "—";
            const rate = Math.abs(b.changeRate || 0).toFixed(1);

            if (b.state === UPowerDeviceState.Charging || b.state === UPowerDeviceState.PendingCharge) {
                batteryChangeRate = "+" + rate + " W";
            } else if (b.state === UPowerDeviceState.FullyCharged) {
                batteryChangeRate = "0.0 W";
            } else {
                batteryChangeRate = "-" + rate + " W";
            }

            switch (b.state) {
                case UPowerDeviceState.Charging:
                case UPowerDeviceState.PendingCharge:
                    batteryStatusLabel = "Carregando";
                    break;
                case UPowerDeviceState.Discharging:
                case UPowerDeviceState.PendingDischarge:
                    batteryStatusLabel = "Descarregando";
                    break;
                case UPowerDeviceState.FullyCharged:
                    batteryStatusLabel = "Totalmente Carregado";
                    break;
                case UPowerDeviceState.Empty:
                    batteryStatusLabel = "Bateria Vazia";
                    break;
                default:
                    batteryStatusLabel = UPowerDeviceState.toString(b.state);
            }

            batteryPercentage = Math.round((b.percentage ?? 0) * 100);

        } else {
            batteryPresent = false;
            batteryCapacity = "—";
            batteryHealth = "—";
            batteryChangeRate = "—";
            batteryStatusLabel = "Sem bateria";
            batteryPercentage = 0;
            chargeCycles = -1;
            chargeCyclesLoaded = false;
            batteryHealthLoaded = false;
        }
        if (batteryPresent && !chargeCyclesProcess.running
                && (!chargeCyclesLoaded || (retryChargeCycles && chargeCycles < 0)))
            chargeCyclesProcess.running = true;
        if (batteryPresent && !batteryHealthProcess.running
                && (!batteryHealthLoaded || (retryChargeCycles && batteryHealth === "—")))
            batteryHealthProcess.running = true;
    }

    Process { id: sessionActionProcess }

    Process {
        id: batteryHealthProcess
        command: ["sh", "-c", "path=$(upower -e | awk '/\\/battery_[^/]+$/ { print; exit }'); [ -n \"$path\" ] || exit 1; busctl --system get-property org.freedesktop.UPower \"$path\" org.freedesktop.UPower.Device Capacity | awk '$1 == \"d\" && $2 ~ /^[0-9]+([.][0-9]+)?$/ { print $2; found=1; exit } END { if (!found) exit 1 }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(text.trim());
                root.batteryHealth = Number.isFinite(value) && value >= 0 && value <= 100
                    ? Math.round(value) + "%" : "—";
            }
        }
        onExited: code => {
            root.batteryHealthLoaded = true;
            if (code !== 0) root.batteryHealth = "—";
        }
    }

    Process {
        id: chargeCyclesProcess
        command: ["sh", "-c", "path=$(upower -e | awk '/\\/battery_[^/]+$/ { print; exit }'); [ -n \"$path\" ] || exit 1; busctl --system get-property org.freedesktop.UPower \"$path\" org.freedesktop.UPower.Device ChargeCycles | awk '$1 == \"i\" && $2 ~ /^[0-9]+$/ { print $2; found=1; exit } END { if (!found) exit 1 }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                root.chargeCycles = /^\d+$/.test(value) ? Number(value) : -1;
            }
        }
        onExited: code => {
            root.chargeCyclesLoaded = true;
            if (code !== 0) root.chargeCycles = -1
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.visible
        onTriggered: root.refresh(false)
    }

    // --- Omarchy Phrase Rotation Timer ---
    Timer {
        interval: 3000
        running: root.visible && root.rotatingPhrases
        repeat: true
        triggeredOnStart: false
        onTriggered: phraseSwap.restart()
    }

    SequentialAnimation {
        id: phraseSwap
        PropertyAnimation { target: heroStatus; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.OutQuad }
        ScriptAction { script: { if (root.activePhrases.length > 0) root.phraseIndex = (root.phraseIndex + 1) % root.activePhrases.length } }
        PropertyAnimation { target: heroStatus; property: "opacity"; to: 1.0; duration: 300; easing.type: Easing.InQuad }
    }

    Connections {
        target: root
        function onRotatingPhrasesChanged() {
            if (!root.rotatingPhrases) {
                phraseSwap.stop()
                heroStatus.opacity = 1.0
            }
        }
    }
    // -------------------------------------

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Config.Theme.colBg
        radius: 16
        border.width: 1
        border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.15)

        // Close Button (Absolute Top-Right)
        Text {
            anchors { top: parent.top; right: parent.right; margins: 14 }
            text: "close"
            color: closeMouse.containsMouse ? Config.Theme.colHighlight : Qt.rgba(Config.Theme.colFg.r, Config.Theme.colFg.g, Config.Theme.colFg.b, 0.4)
            font { family: "Material Symbols Rounded"; pixelSize: 20 }
            z: 10

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.visible = false
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 20
        }
        spacing: 20

        // 1. Hero Section (Omarchy Style)
        Row {
            width: parent.width
            spacing: 16

            Text {
                text: root.batteryIconName
                // A cor agora respeita crítico/low igualzinho ao módulo
                color: root.isCharging ? Config.Theme.colGreen : (root.isCritical ? Config.Theme.colBatteryCritical : (root.isLow ? Config.Theme.colYellow : Config.Theme.colHighlight))
                font { family: "Material Symbols Rounded"; pixelSize: 42 }
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                width: parent.width - 42 - 16 - 80 - 16 // Calculate remaining space

                Text {
                    text: "Bateria"
                    color: Config.Theme.colFg
                    font { family: Config.Theme.fontFamily; pixelSize: 18; bold: true }
                }

                Text {
                    id: heroStatus
                    text: (root.isFullyCharged ? "CARGA COMPLETA" :
                          (root.rotatingPhrases ? root.activePhrases[root.phraseIndex % root.activePhrases.length] : root.batteryStatusLabel)).toUpperCase()
                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.8)
                    font { family: Config.Theme.fontFamily; pixelSize: 10; bold: true; letterSpacing: 1.2 }
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

                Text {
                    text: Math.round(root.batteryPercentage) + "%"
                    visible: root.batteryPresent
                    color: Config.Theme.colFg
                    font { family: Config.Theme.fontFamily; pixelSize: 36; bold: true }
                    anchors.verticalCenter: parent.verticalCenter
                    width: 80
                    horizontalAlignment: Text.AlignRight
                }
        }

        // 2. Animated Progress Bar
        Item {
            width: parent.width
            implicitHeight: 8
            visible: root.batteryPresent

            Rectangle {
                id: barTrack
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(Config.Theme.colFg.r, Config.Theme.colFg.g, Config.Theme.colFg.b, 0.1)
            }

            Rectangle {
                id: barFill
                anchors.left: barTrack.left
                anchors.verticalCenter: barTrack.verticalCenter
                height: barTrack.height
                radius: barTrack.radius
                // A cor da barra também acompanha a cor do ícone
                color: root.isCharging ? Config.Theme.colGreen : (root.isCritical ? Config.Theme.colBatteryCritical : (root.isLow ? Config.Theme.colYellow : Config.Theme.colHighlight))
                width: Math.max(barTrack.height, barTrack.width * (root.batteryPercentage / 100))

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 250 } }

                SequentialAnimation on opacity {
                    running: root.isCharging && !root.isFullyCharged && root.visible
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { from: 1.0; to: 0.5; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.5; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }
        }

        // 3. Battery information grid
        Row {
            width: parent.width
            spacing: 16
            visible: root.batteryPresent

            Column {
                width: (parent.width - 16) / 2
                spacing: 10

                InfoPair { label: "Saúde"; value: root.batteryHealth }
                InfoPair { label: "Ciclos"; value: root.chargeCycles >= 0 ? String(root.chargeCycles) : "—" }
                InfoPair { label: "Capacidade"; value: root.batteryCapacity + " Wh" }
            }

            Column {
                width: (parent.width - 16) / 2
                spacing: 10

                InfoPair { label: "Potência"; value: root.batteryChangeRate }
                InfoPair {
                    label: root.isCharging ? "Até carga completa" : "Autonomia estimada"
                    value: root.estimatedTime
                }
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: 1
            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.15)
            visible: Services.PowerProfiles.isAvailable
        }

        // 4. Power Profile Picker
        Column {
            width: parent.width
            visible: Services.PowerProfiles.isAvailable
            spacing: 12

            Text {
                text: "PERFIL DE ENERGIA"
                color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.8)
                font { family: Config.Theme.fontFamily; pixelSize: 10; bold: true; letterSpacing: 1.2 }
            }

            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: Services.PowerProfiles.availableProfiles

                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool active: Services.PowerProfiles.activeProfile === modelData

                        width: (parent.width - (8 * 2)) / 3
                        implicitHeight: 48
                        radius: 8

                        color: active ? Config.Theme.colHighlight
                                      : (profileMouse.containsMouse ? Qt.rgba(Config.Theme.colFg.r, Config.Theme.colFg.g, Config.Theme.colFg.b, 0.1)
                                                                    : "transparent")

                        border.width: 1
                        border.color: active ? Config.Theme.colHighlight : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.2)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: Services.PowerProfiles.getProfileIcon(modelData)
                                color: active ? Config.Theme.colBg : Config.Theme.colFg
                                font { family: "Material Symbols Rounded"; pixelSize: 18 }
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                text: Services.PowerProfiles.getProfileLabel(modelData)
                                color: active ? Config.Theme.colBg : Config.Theme.colFg
                                font { family: Config.Theme.fontFamily; pixelSize: 12; bold: active }
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: profileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.PowerProfiles.setProfile(modelData)
                        }
                    }
                }
            }
        }
    }

    // --- Inline Component for Stats Grid ---
    component InfoPair: Row {
        property string label: ""
        property string value: ""
        property color valueColor: Config.Theme.colFg

        width: parent.width

        Text {
            text: label
            color: Config.Theme.colTextSec
            font { family: Config.Theme.fontFamily; pixelSize: 12 }
            width: parent.width * 0.5
            elide: Text.ElideRight
        }

        Text {
            text: value
            color: valueColor
            font { family: Config.Theme.fontFamily; pixelSize: 12; bold: true }
            width: parent.width * 0.5
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }
}
