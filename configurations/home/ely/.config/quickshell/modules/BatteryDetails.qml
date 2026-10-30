import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import ".." as Config
import "../services" as Services
import "../services/BatteryRules.js" as BatteryRules

Item {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryPresent: battery?.isPresent ?? false
    readonly property int batteryPercentage: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool isCharging: battery?.state === UPowerDeviceState.Charging
        || battery?.state === UPowerDeviceState.PendingCharge
    readonly property bool isFullyCharged: battery?.state === UPowerDeviceState.FullyCharged
    readonly property bool isDischarging: battery?.state === UPowerDeviceState.Discharging
        || battery?.state === UPowerDeviceState.PendingDischarge
    readonly property bool isPluggedIn: isCharging || isFullyCharged
    readonly property bool isLow: BatteryRules.isLow(batteryPercentage, isPluggedIn)
    readonly property bool isCritical: BatteryRules.isCritical(batteryPercentage, isPluggedIn)
    readonly property string batteryStatus: {
        if (!batteryPresent)
            return "Nenhuma bateria detectada";
        if (isFullyCharged)
            return "Carga completa";
        if (isCharging)
            return "Carregando";
        if (isDischarging)
            return "Descarregando";
        return UPowerDeviceState.toString(battery.state);
    }
    readonly property real estimatedTimeSeconds: !batteryPresent ? 0
        : (isCharging ? (battery.timeToFull ?? 0)
           : (isDischarging ? (battery.timeToEmpty ?? 0) : 0))
    readonly property string estimatedTime: formatDuration(estimatedTimeSeconds)
    readonly property bool compactWidth: width < 340
    readonly property color levelColor: isCharging ? Config.Theme.colGreen
        : (isCritical ? Config.Theme.colBatteryCritical
           : (isLow ? Config.Theme.colYellow : Config.Theme.colHighlight))

    readonly property string batteryCapacity: {
        const capacity = Number(battery?.energyCapacity ?? 0);
        return batteryPresent && Number.isFinite(capacity) && capacity > 0
            ? capacity.toFixed(1) : "—";
    }
    property string batteryHealth: "—"
    property int chargeCycles: -1

    implicitWidth: 380
    implicitHeight: batteryContent.implicitHeight

    function formatDuration(seconds) {
        const minutes = Math.round(Number(seconds) / 60);
        if (!Number.isFinite(minutes) || minutes <= 0)
            return "—";
        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;
        return hours > 0 ? hours + " h " + remainingMinutes + " min" : minutes + " min";
    }

    function readHardwareStats() {
        if (!batteryPresent)
            return;
        batteryHealthProcess.running = true;
        chargeCyclesProcess.running = true;
    }

    Component.onCompleted: {
        Services.PowerProfiles.updateActiveProfile();
        readHardwareStats();
    }

    Connections {
        target: root
        function onBatteryPresentChanged() {
            if (root.batteryPresent && root.chargeCycles < 0)
                root.readHardwareStats();
        }
    }

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
            if (code !== 0)
                root.batteryHealth = "—";
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
            if (code !== 0)
                root.chargeCycles = -1;
        }
    }

    ColumnLayout {
        id: batteryContent
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Config.Theme.spaceMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceMd

            Text {
                text: root.batteryPresent ? "battery_full" : "battery_alert"
                color: root.batteryPresent ? root.levelColor : Config.Theme.colMuted
                font.family: "Material Symbols Rounded"
                font.pixelSize: 30
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Bateria"
                    color: Config.Theme.colFg
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSize
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.batteryStatus
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: root.batteryPresent
                text: root.batteryPercentage + "%"
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeLarge
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.batteryPresent
            height: 8
            radius: height / 2
            color: Config.Theme.colSurfaceRaised

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.batteryPercentage / 100))
                height: parent.height
                radius: parent.radius
                color: root.levelColor
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: !root.batteryPresent
            text: "As informações e os perfis aparecem quando uma bateria é detectada."
            color: Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.batteryPresent
            columns: root.compactWidth ? 1 : 2
            columnSpacing: Config.Theme.spaceSm
            rowSpacing: Config.Theme.spaceSm

            Repeater {
                model: [
                    { label: "Saúde", value: root.batteryHealth },
                    { label: "Ciclos", value: root.chargeCycles >= 0 ? String(root.chargeCycles) : "—" },
                    { label: "Capacidade", value: root.batteryCapacity === "—" ? "—" : root.batteryCapacity + " Wh" },
                    { label: "Potência", value: root.battery ? (Math.abs(root.battery.changeRate || 0).toFixed(1) + " W") : "—" },
                    { label: root.isCharging ? "Até carga completa" : "Autonomia estimada", value: root.estimatedTime }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 58
                    radius: Config.Theme.radiusCard
                    color: Config.Theme.colSurface

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Config.Theme.spaceSm
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall - 1
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.value
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Services.PowerProfiles.isAvailable
            height: 1
            color: Config.Theme.colBorderSubtle
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceSm
            visible: Services.PowerProfiles.isAvailable

            Text {
                text: "Perfil de energia"
                color: Config.Theme.colTextSec
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.Theme.spaceXs

                Repeater {
                    model: Services.PowerProfiles.availableProfiles

                    delegate: Button {
                        id: profileButton
                        required property string modelData
                        readonly property bool selected: Services.PowerProfiles.activeProfile === modelData
                        Layout.fillWidth: true
                        implicitHeight: 42
                        activeFocusOnTab: true
                        Accessible.name: "Perfil de energia " + Services.PowerProfiles.getProfileLabel(modelData)
                            + (selected ? ", ativo" : "")
                        ToolTip.text: Services.PowerProfiles.getProfileLabel(modelData)
                        ToolTip.visible: root.compactWidth && hovered
                        onClicked: Services.PowerProfiles.setProfile(modelData)

                        contentItem: RowLayout {
                            spacing: 4
                            Text {
                                text: Services.PowerProfiles.getProfileIcon(modelData)
                                color: profileButton.selected
                                    ? Config.Theme.colOnHighlightContainer : Config.Theme.colTextSec
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                            }
                            Text {
                                visible: !root.compactWidth
                                Layout.fillWidth: true
                                text: Services.PowerProfiles.getProfileLabel(modelData)
                                color: profileButton.selected
                                    ? Config.Theme.colOnHighlightContainer : Config.Theme.colFg
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall - 1
                                font.bold: profileButton.selected
                                elide: Text.ElideRight
                            }
                        }

                        background: Rectangle {
                            radius: Config.Theme.radiusControl
                            color: profileButton.selected || profileButton.hovered || profileButton.activeFocus
                                ? Config.Theme.colHighlightContainer : Config.Theme.colSurface
                            border.width: profileButton.activeFocus ? 1 : 0
                            border.color: Config.Theme.colHighlight
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: !Services.PowerProfiles.isAvailable
            text: "Perfis de energia indisponíveis neste sistema."
            color: Config.Theme.colMuted
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
        }
    }
}
