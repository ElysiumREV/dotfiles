import "." as QsModules
import "../." as Config
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Wayland
import "../services" as Services
import "../widgets" as Widgets

Variants {
    model: Quickshell.screens

    delegate: Component {
        Item {
            /*
             * =========================================================
             * CANTOS INFERIORES DA TELA
             * =========================================================
             *
             * Essa é uma janela separada porque o PanelWindow da barra
             * ocupa somente a região superior da tela.
             *
             * Ela é transparente e só possui os dois RoundCorner.
             */

            required property var modelData
            readonly property int adaptiveLayout: modelData.width <= Config.Theme.barMinimalWidthThreshold
                ? 2
                : (modelData.width <= Config.Theme.barCompactWidthThreshold ? 1 : 0)

            /*
             * =========================================================
             * BARRA SUPERIOR
             * =========================================================
             */
            PanelWindow {
                id: root

                Component.onCompleted: Services.GlobalFocusGrab.addPersistent(root)
                Component.onDestruction: Services.GlobalFocusGrab.removePersistent(root)

                screen: modelData
                margins.top: Config.Theme.barInset
                margins.left: Config.Theme.barInset
                margins.right: Config.Theme.barInset
                margins.bottom: Config.Theme.barInset
                implicitHeight: Config.Theme.barHeight + Config.Theme.screenRadius
                color: "transparent"
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: Config.Theme.barHeight
                WlrLayershell.layer: WlrLayer.Bottom

                anchors {
                    top: true
                    left: true
                    right: true
                }

                Item {
                    id: barMask

                    height: Config.Theme.barHeight

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Config.Theme.screenRadius
                    }

                }

                /*
                 * =====================================================
                 * SUPERFÍCIE DA BARRA
                 * =====================================================
                 */
                Rectangle {
                    id: barSurface

                    height: Config.Theme.barHeight
                    radius: Config.Theme.barRadius
                    color: Qt.rgba(Config.Theme.colBg.r, Config.Theme.colBg.g, Config.Theme.colBg.b)
                    clip: true

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: Config.Theme.barContentMargin
                        anchors.rightMargin: Config.Theme.barContentMargin

                        Widgets.PopupLoadState {
                            id: launcherPopupState
                            requested: Services.WindowControl.launcherVisible
                                && Hyprland.monitorFor(modelData) === Services.WindowControl.launcherMonitor
                        }

                        Widgets.PopupLoadState {
                            id: clipboardPopupState
                            requested: Services.WindowControl.clipboardVisible
                                && Hyprland.monitorFor(modelData) === Services.WindowControl.clipboardMonitor
                        }

                        Widgets.PopupLoadState {
                            id: wallpaperPopupState
                            requested: Services.WindowControl.wallpaperVisible
                                && Hyprland.monitorFor(modelData) === Services.WindowControl.wallpaperMonitor
                        }

                        Widgets.PopupLoadState {
                            id: wallhavenPopupState
                            requested: Services.WindowControl.wallhavenVisible
                                && Hyprland.monitorFor(modelData) === Services.WindowControl.wallhavenMonitor
                        }

                        QsModules.ModuleGroup {
                            id: focusedAppGroup

                            backgroundVisible: false
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Config.Preferences.bar.showFocusedApp && adaptiveLayout < 2
                            contentWidth: visible ? Math.max(0, Math.min(
                                focusedAppTitle.implicitWidth,
                                adaptiveLayout === 0 ? 320 : 180,
                                mediaGroup.x - Config.Theme.moduleSpacing - 12
                            )) : 0
                        }

                        Text {
                            id: focusedAppTitle

                            visible: focusedAppGroup.visible
                            anchors.left: focusedAppGroup.left
                            anchors.leftMargin: 6
                            anchors.right: focusedAppGroup.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: Hyprland.activeToplevel?.title || "Área de trabalho"
                            color: Config.Theme.colFg
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                        }

                        /*
                         * =================================================
                         * MENUS SOB DEMANDA
                         * =================================================
                         */
                        LazyLoader {
                            activeAsync: launcherPopupState.active

                            QsModules.ApplicationLauncher {
                                targetScreen: modelData
                                keepVisible: launcherPopupState.active
                            }
                        }

                        LazyLoader {
                            activeAsync: clipboardPopupState.active

                            QsModules.ClipboardHistoryMenu {
                                targetScreen: modelData
                                keepVisible: clipboardPopupState.active
                            }
                        }

                        LazyLoader {
                            activeAsync: wallpaperPopupState.active

                            Widgets.Wallpaper {
                                targetScreen: modelData
                                keepVisible: wallpaperPopupState.active
                            }
                        }

                        LazyLoader {
                            activeAsync: wallhavenPopupState.active

                            Widgets.Wallhaven {
                                targetScreen: modelData
                                keepVisible: wallhavenPopupState.active
                            }
                        }

                        LazyLoader {
                            id: archMenuLoader
                            activeAsync: Services.Notifications.centerVisible
                                && Services.Notifications.centerMonitor === Hyprland.monitorFor(modelData)

                            ArchMenu {
                                targetScreen: modelData
                                positionProvider: (popupWidth) => {
                                    const position = deviceGroup.QsWindow.mapFromItem(
                                        deviceGroup, 0, 0
                                    );
                                    const desiredRight = modelData.width
                                        - (position.x + deviceGroup.width);
                                    const maxRight = Math.max(0, modelData.width - popupWidth);
                                    return { "right": Math.max(0, Math.min(desiredRight, maxRight)) };
                                }
                            }

                            onActiveChanged: if (active && item) item.openMenu()
                        }

                        /*
                         * =================================================
                         * MÓDULOS DA DIREITA
                         * =================================================
                         */
                        Row {
                            id: rightModulesRow
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: Config.Theme.barHeight
                            spacing: Config.Theme.moduleSpacing

                            QsModules.Tray {
                                anchors.verticalCenter: parent.verticalCenter
                                window: root
                                visible: Config.Preferences.bar.showTray
                            }

                            QsModules.ModuleGroup {
                                id: deviceGroup
                                contentWidth: deviceIndicators.implicitWidth
                                visible: Config.Preferences.bar.showDeviceIndicators
                                interactive: true
                                backgroundVisible: false
                                selected: Services.Notifications.centerVisible
                                    && Services.Notifications.centerMonitor === Hyprland.monitorFor(modelData)
                                anchors.verticalCenter: parent.verticalCenter
                                Accessible.role: Accessible.Button
                                Accessible.name: "Abrir controles rápidos e notificações"
                                activeFocusOnTab: true

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                            || event.key === Qt.Key_Space) {
                                        Services.Notifications.toggleCenter(Hyprland.monitorFor(modelData));
                                        event.accepted = true;
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: 0
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Services.Notifications.toggleCenter(Hyprland.monitorFor(modelData))
                                }

                                Row {
                                    id: deviceIndicators

                                    anchors.centerIn: parent
                                    spacing: Config.Theme.moduleSpacing

                                    QsModules.Volume {
                                        id: volumeItem
                                        groupHighlighted: deviceGroup.highlighted

                                        anchors.verticalCenter: parent.verticalCenter
                                        onRequestMenu: {
                                            Services.Notifications.toggleCenter(Hyprland.monitorFor(modelData));
                                        }
                                    }

                                    QsModules.Microphone {
                                        groupHighlighted: deviceGroup.highlighted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    QsModules.Battery {
                                        id: batteryItem
                                        groupHighlighted: deviceGroup.highlighted
                                        anchors.verticalCenter: parent.verticalCenter
                                        onRequestMenu: Services.Notifications.toggleCenter(
                                            Hyprland.monitorFor(modelData)
                                        )
                                    }

                                    Item {
                                        id: networkIndicator
                                        width: 18
                                        height: Config.Theme.moduleHeight
                                        Accessible.role: Accessible.StaticText
                                        Accessible.name: !Networking.wifiEnabled ? "Wi-Fi desativado"
                                            : (connectedWifi ? "Wi-Fi conectado a " + connectedWifi.name : "Wi-Fi desconectado")

                                        readonly property var wifiDevice: {
                                            for (const device of Networking.devices.values) {
                                                if (device.type === DeviceType.Wifi)
                                                    return device;
                                            }
                                            return null;
                                        }
                                        readonly property var connectedWifi: {
                                            const networks = wifiDevice?.networks?.values ?? [];
                                            return networks.find(network => network.connected) ?? null;
                                        }
                                        readonly property string iconName: {
                                            if (!Networking.wifiEnabled)
                                                return "wifi_off";
                                            if (!connectedWifi)
                                                return "signal_wifi_0_bar";
                                            const signal = Math.round((connectedWifi.signalStrength ?? 0) * 100);
                                            if (signal >= 75) return "wifi";
                                            if (signal >= 50) return "network_wifi_3_bar";
                                            if (signal >= 25) return "network_wifi_2_bar";
                                            return "network_wifi_1_bar";
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: networkIndicator.iconName
                                            color: deviceGroup.highlighted ? Config.Theme.colOnHighlightContainer
                                                : (networkIndicator.connectedWifi
                                                    ? Config.Theme.colHighlight : Config.Theme.colMuted)
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.Notifications.toggleCenter(Hyprland.monitorFor(modelData))
                                        }
                                    }

                                    Item {
                                        id: bluetoothIndicator
                                        width: 18 + (Services.Notifications.doNotDisturb
                                            ? 18 + Config.Theme.moduleSpacing : 0)
                                        height: Config.Theme.moduleHeight
                                        readonly property var connectedDevice: Bluetooth.devices.values.find(device => device.connected) ?? null
                                        Accessible.role: Accessible.StaticText
                                        Accessible.name: (connectedDevice
                                            ? "Bluetooth conectado a " + (connectedDevice.name || "dispositivo")
                                            : (Bluetooth.defaultAdapter?.enabled ? "Bluetooth ativo, sem conexão" : "Bluetooth desativado"))
                                            + (Services.Notifications.doNotDisturb ? "; Não Perturbe ativado" : "")

                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Bluetooth.defaultAdapter?.enabled ? "bluetooth" : "bluetooth_disabled"
                                            color: deviceGroup.highlighted ? Config.Theme.colOnHighlightContainer
                                                : (bluetoothIndicator.connectedDevice
                                                    ? Config.Theme.colHighlight : Config.Theme.colMuted)
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 18 + Config.Theme.moduleSpacing
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: Services.Notifications.doNotDisturb
                                            text: "notifications_off"
                                            color: deviceGroup.highlighted ? Config.Theme.colOnHighlightContainer
                                                : Config.Theme.colHighlight
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 18
                                            Accessible.ignored: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.Notifications.toggleCenter(Hyprland.monitorFor(modelData))
                                        }
                                    }
                                }

                            }

                        }

                        /*
                         * =================================================
                         * WORKSPACES
                         * =================================================
                         */
                        QsModules.ModuleGroup {
                            id: workspaceGroup

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: workspaces.implicitWidth

                            QsModules.Workspaces {
                                id: workspaces
                                buttonSize: adaptiveLayout === 0 ? 26 : (adaptiveLayout === 1 ? 24 : 22)
                                spacing: adaptiveLayout === 2 ? 2 : 4

                                anchors.centerIn: parent
                            }

                        }

                        QsModules.ModuleGroup {
                            id: clockGroup
                            anchors.left: workspaceGroup.right
                            anchors.leftMargin: Config.Theme.moduleSpacing
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: clock.implicitWidth

                            QsModules.Clock {
                                id: clock
                                targetScreen: modelData
                                screenWidth: modelData.width
                                showDate: Config.Preferences.bar.showDate && adaptiveLayout < 2
                                anchors.centerIn: parent
                            }
                        }

                        /*
                         * =================================================
                         * MEDIA
                         * =================================================
                         */
                        QsModules.ModuleGroup {
                            id: mediaGroup
                            visible: Config.Preferences.bar.showMedia && adaptiveLayout === 0

                            anchors.right: systemStatusGroup.left
                            anchors.rightMargin: visible ? Config.Theme.moduleSpacing : 0
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: visible ? media.implicitWidth : 0

                            QsModules.Media {
                                id: media

                                targetScreen: modelData
                                anchors.centerIn: parent
                                screenWidth: modelData.width
                            }

                        }

                        /*
                         * =================================================
                         * SYSTEM STATUS
                         * =================================================
                         */
                        QsModules.ModuleGroup {
                            id: systemStatusGroup
                            visible: Config.Preferences.bar.showSystemStatus

                            anchors.right: workspaceGroup.left
                            anchors.rightMargin: visible ? Config.Theme.moduleSpacing : 0
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: systemStatus.implicitWidth

                            QsModules.SystemStatus {
                                id: systemStatus

                                targetScreen: modelData
                                anchors.centerIn: parent
                                screenWidth: modelData.width
                            }

                        }

                    }

                }

                /*
                 * =========================================================
                 * CANTOS DA BARRA
                 * =========================================================
                 */
                QsModules.RoundCorner {
                    id: topLeftCorner

                    implicitSize: Config.Theme.screenRadius
                    color: Config.Theme.colBg
                    corner: QsModules.RoundCorner.CornerEnum.TopLeft

                    anchors {
                        left: parent.left
                        top: barSurface.bottom
                    }

                }

                QsModules.RoundCorner {
                    id: topRightCorner

                    implicitSize: Config.Theme.screenRadius
                    color: Config.Theme.colBg
                    corner: QsModules.RoundCorner.CornerEnum.TopRight

                    anchors {
                        right: parent.right
                        top: barSurface.bottom
                    }

                }

                /*
                 * Máscara da barra.
                 */
                mask: Region {
                    item: barMask
                }

            }

            PanelWindow {
                id: bottomLeftCornerWindow

                screen: modelData
                implicitWidth: Config.Theme.screenRadius
                implicitHeight: Config.Theme.screenRadius
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.layer: WlrLayer.Bottom

                anchors {
                    left: true
                    bottom: true
                }

                QsModules.RoundCorner {
                    id: bottomLeftCorner

                    anchors.fill: parent
                    implicitSize: Config.Theme.screenRadius
                    color: Config.Theme.colBg
                    corner: QsModules.RoundCorner.CornerEnum.BottomLeft
                }

                mask: Region {
                    item: bottomLeftCorner
                }

            }

            PanelWindow {
                id: bottomRightCornerWindow

                screen: modelData
                implicitWidth: Config.Theme.screenRadius
                implicitHeight: Config.Theme.screenRadius
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.layer: WlrLayer.Bottom

                anchors {
                    right: true
                    bottom: true
                }

                QsModules.RoundCorner {
                    id: bottomRightCorner

                    anchors.fill: parent
                    implicitSize: Config.Theme.screenRadius
                    color: Config.Theme.colBg
                    corner: QsModules.RoundCorner.CornerEnum.BottomRight
                }

                mask: Region {
                    item: bottomRightCorner
                }

            }

        }

    }

}
