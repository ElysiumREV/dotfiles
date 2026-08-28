import Quickshell
import Quickshell.Services.UPower
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
    property int chargeCycles: -1

    color: "transparent"
    visible: false
    implicitWidth: 320
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

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isPresent ?? false
    readonly property string capacity: hasBattery ? battery.energyCapacity.toFixed(0) : "—"
    readonly property string changeRate: {
        if (!hasBattery) return "—"
        const rate = Math.abs(battery.changeRate).toFixed(1)
        return battery.state === UPowerDeviceState.Charging
            || battery.state === UPowerDeviceState.PendingCharge
            ? "+" + rate + " W"
            : battery.state === UPowerDeviceState.FullyCharged
              ? "0.0 W"
              : "-" + rate + " W"
    }
    readonly property string statusLabel: {
        if (!hasBattery) return "Sem bateria"
        switch (battery.state) {
        case UPowerDeviceState.Charging:
        case UPowerDeviceState.PendingCharge:
            return "Carregando"
        case UPowerDeviceState.Discharging:
        case UPowerDeviceState.PendingDischarge:
            return "Descarregando"
        case UPowerDeviceState.FullyCharged:
            return "Carregado"
        case UPowerDeviceState.Empty:
            return "Vazio"
        default:
            return UPowerDeviceState.toString(battery.state)
        }
    }

    function openMenu() {
        popupX = positionProvider(implicitWidth).x;
        refresh();
        visible = true;
    }

    function refresh() {
        Services.PowerProfiles.updateActiveProfile();
        chargeCyclesProcess.running = true;
    }

    Process {
        id: chargeCyclesProcess
        command: ["sh", "-c", "path=/org/freedesktop/UPower/devices/battery_$(upower -e | sed -n 's#.*/battery_\\([^/]*\\)$#\\1#p' | head -1); [ -n \"$path\" ] && busctl --system get-property org.freedesktop.UPower \"$path\" org.freedesktop.UPower.Device ChargeCycles 2>/dev/null || echo 'i -1'"]

        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                const match = data.trim().match(/^i\s+(-?\d+)/)
                if (match)
                    root.chargeCycles = parseInt(match[1])
            }
        }
        onExited: code => {
            if (code !== 0)
                root.chargeCycles = -1
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

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
                text: root.battery?.iconName ?? "battery_full"
                color: Config.Theme.colHighlight
                font { family: "Material Symbols Rounded"; pixelSize: 22 }
            }

            Text {
                Layout.fillWidth: true
                text: "Bateria"
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
                font { family: "Material Symbols Rounded"; pixelSize: 20 }

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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: (root.battery?.percentage ?? 0) + "%"
                    color: Config.Theme.colFg
                    font {
                        family: Config.Theme.fontFamily
                        pixelSize: Config.Theme.fontSizeLarge
                        bold: true
                    }
                }
                Text {
                    text: root.capacity + " Wh"
                    color: Config.Theme.colMuted
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall }
                }
            }

            Text {
                text: root.statusLabel
                color: {
                    const state = root.battery?.state ?? -1
                    if (state === UPowerDeviceState.Charging
                        || state === UPowerDeviceState.FullyCharged)
                        return Config.Theme.colGreen
                    return Config.Theme.colFg
                }
                font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall; bold: true }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "bolt"
                    color: Config.Theme.colYellow
                    font { family: "Material Symbols Rounded"; pixelSize: 18 }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Taxa de energia"
                    color: Config.Theme.colFg
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall }
                }
                Text {
                    text: root.changeRate
                    color: Config.Theme.colTextSec
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall; bold: true }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "loop"
                    color: Config.Theme.colBlue
                    font { family: "Material Symbols Rounded"; pixelSize: 18 }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Ciclos de carga"
                    color: Config.Theme.colFg
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall }
                }
                Text {
                    text: root.chargeCycles >= 0 ? String(root.chargeCycles) : "—"
                    color: Config.Theme.colTextSec
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSizeSmall; bold: true }
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
            visible: Services.PowerProfiles.isAvailable
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "power"
                    color: Config.Theme.colHighlight
                    font { family: "Material Symbols Rounded"; pixelSize: 20 }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Perfil de energia"
                    color: Config.Theme.colFg
                    font { family: Config.Theme.fontFamily; pixelSize: Config.Theme.fontSize; bold: true }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: Services.PowerProfiles.availableProfiles

                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool active: Services.PowerProfiles.activeProfile === modelData
                        Layout.fillWidth: true
                        implicitHeight: 54
                        radius: 8
                        color: active ? Config.Theme.colHighlight
                              : profileMouse.containsMouse
                                ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.18)
                                : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.10)

                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Services.PowerProfiles.getProfileIcon(modelData)
                                color: active ? Config.Theme.colBg : Config.Theme.colFg
                                font { family: Config.Theme.fontFamily; pixelSize: 20 }
                            }
                            Text {
                                text: Services.PowerProfiles.getProfileLabel(modelData)
                                color: active ? Config.Theme.colBg : Config.Theme.colFg
                                font { family: Config.Theme.fontFamily; pixelSize: 10; bold: active }
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
}
