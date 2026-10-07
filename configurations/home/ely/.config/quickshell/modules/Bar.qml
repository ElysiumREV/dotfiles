import "." as QsModules
import "../." as Config
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
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

            /*
             * =========================================================
             * BARRA SUPERIOR
             * =========================================================
             */
            PanelWindow {
                id: root

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

                        /*
                         * =================================================
                         * ARCH MENU
                         * =================================================
                         */
                        QsModules.ModuleGroup {
                            id: leftControlsGroup

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: archPlaceholder.implicitWidth
                                          + launcherPlaceholder.implicitWidth
                                          + wallpaperPlaceholder.implicitWidth
                                          + wallhavenPlaceholder.implicitWidth + 30
                            z: -1
                        }

                        Text {
                            id: archPlaceholder

                            anchors.left: leftControlsGroup.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: Config.Theme.colHighlight
                            verticalAlignment: Text.AlignVCenter

                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: 20
                            }

                        }

                        Text {
                            id: launcherPlaceholder

                            anchors.left: archPlaceholder.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "apps"
                            color: launcherMouse.containsMouse
                                   ? Config.Theme.colHighlight : Config.Theme.colFg
                            verticalAlignment: Text.AlignVCenter

                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 19
                            }
                        }

                        QsModules.ApplicationLauncher {
                            id: applicationLauncher
                            targetScreen: modelData
                        }

                        Text {
                            id: wallpaperPlaceholder

                            anchors.left: launcherPlaceholder.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "wallpaper"
                            color: wallpaperMouse.containsMouse
                                ? Config.Theme.colHighlight : Config.Theme.colFg
                            verticalAlignment: Text.AlignVCenter
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 19
                            }
                        }

                        Widgets.Wallpaper {
                            id: wallpaperPicker
                            targetScreen: modelData
                        }

                        MouseArea {
                            id: wallpaperMouse
                            anchors.fill: wallpaperPlaceholder
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Services.WindowControl.wallpaperVisible)
                                    wallpaperPicker.closePicker();
                                else
                                    wallpaperPicker.openPicker();
                            }
                        }

                        Text {
                            id: wallhavenPlaceholder
                            anchors.left: wallpaperPlaceholder.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "travel_explore"
                            color: wallhavenMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colFg
                            verticalAlignment: Text.AlignVCenter
                            font {
                                family: "Material Symbols Rounded"
                                pixelSize: 19
                            }
                        }

                        Widgets.Wallhaven {
                            id: wallhavenPicker
                            targetScreen: modelData
                        }

                        MouseArea {
                            id: wallhavenMouse
                            anchors.fill: wallhavenPlaceholder
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Services.WindowControl.wallhavenVisible)
                                    wallhavenPicker.closePicker();
                                else
                                    wallhavenPicker.openPicker();
                            }
                        }

                        MouseArea {
                            id: launcherMouse
                            anchors.fill: launcherPlaceholder
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Services.WindowControl.launcherVisible)
                                    applicationLauncher.closeLauncher();
                                else
                                    applicationLauncher.openLauncher();
                            }
                        }

                        ArchMenu {
                            id: archMenu

                            positionProvider: (popupWidth) => {
                                const position = archPlaceholder.QsWindow.mapFromItem(archPlaceholder, 0, 0);
                                const desiredX = Math.max(Config.Theme.barContentMargin, position.x);
                                const screenWidth = modelData.width;
                                const maxX = screenWidth - popupWidth;
                                const clampedX = Math.min(Math.max(desiredX, 0), maxX);
                                return {
                                    "x": clampedX,
                                    "y": position.y
                                };
                            }
                        }

                        MouseArea {
                            anchors.fill: archPlaceholder
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (archMenu.visible)
                                    archMenu.visible = false;
                                else
                                    archMenu.openMenu();
                            }
                        }

                        /*
                         * =================================================
                         * MÓDULOS DA DIREITA
                         * =================================================
                         */
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: Config.Theme.barHeight
                            spacing: Config.Theme.moduleSpacing

                            QsModules.Tray {
                                anchors.verticalCenter: parent.verticalCenter
                                window: root
                            }

                            QsModules.ModuleGroup {
                                contentWidth: deviceIndicators.implicitWidth
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    id: deviceIndicators

                                    anchors.centerIn: parent
                                    spacing: Config.Theme.moduleSpacing

                                    QsModules.Volume {
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    QsModules.Battery {
                                        id: batteryItem

                                        anchors.verticalCenter: parent.verticalCenter
                                        onRequestMenu: {
                                            if (batteryMenu.visible)
                                                batteryMenu.visible = false;
                                            else
                                                batteryMenu.openMenu();
                                        }
                                    }

                                    Item {
                                        id: notificationAnchor
                                        width: 22
                                        height: Config.Theme.moduleHeight

                                        Text {
                                            anchors.centerIn: parent
                                            text: Services.Notifications.unreadCount > 0
                                                ? "notifications_active" : "notifications_none"
                                            color: notificationMouse.containsMouse
                                                ? Config.Theme.colHighlight : Config.Theme.colFg
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 19
                                        }

                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.topMargin: 4
                                            width: Services.Notifications.unreadCount > 9 ? 14 : 8
                                            height: 8
                                            radius: 4
                                            visible: Services.Notifications.unreadCount > 0
                                            color: Config.Theme.colRed

                                            Text {
                                                anchors.centerIn: parent
                                                visible: Services.Notifications.unreadCount > 9
                                                text: "9+"
                                                color: Config.Theme.colBg
                                                font.family: Config.Theme.fontFamily
                                                font.pixelSize: 7
                                                font.bold: true
                                            }
                                        }

                                        MouseArea {
                                            id: notificationMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Services.Notifications.toggleCenter(Hyprland.monitorFor(modelData))
                                        }
                                    }

                                }

                            }

                            QsModules.BatteryMenu {
                                id: batteryMenu
                                targetScreen: modelData

                                positionProvider: (popupWidth) => {
                                    const position = batteryItem.QsWindow.mapFromItem(batteryItem, 0, 0);
                                    const screenWidth = modelData.width;
                                    const desiredRight = screenWidth - (position.x + batteryItem.width);
                                    const maxRight = Math.max(0, screenWidth - popupWidth);
                                    return {
                                        "right": Math.max(0, Math.min(desiredRight, maxRight))
                                    };
                                }
                            }

                            QsModules.NotificationCenter {
                                targetScreen: modelData
                                positionProvider: popupWidth => {
                                    const position = notificationAnchor.QsWindow.mapFromItem(notificationAnchor, 0, 0);
                                    const desiredRight = modelData.width - (position.x + notificationAnchor.width);
                                    const maxRight = Math.max(0, modelData.width - popupWidth);
                                    return { "right": Math.max(0, Math.min(desiredRight, maxRight)) };
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

                            anchors.right: systemStatusGroup.left
                            anchors.rightMargin: Config.Theme.moduleSpacing
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: media.implicitWidth

                            QsModules.Media {
                                id: media

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

                            anchors.right: workspaceGroup.left
                            anchors.rightMargin: Config.Theme.moduleSpacing
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: systemStatus.implicitWidth

                            QsModules.SystemStatus {
                                id: systemStatus

                                anchors.centerIn: parent
                                screenWidth: modelData.width
                            }

                        }

                        /*
                         * =================================================
                         * CLOCK
                         * =================================================
                         */
                        QsModules.ModuleGroup {
                            anchors.left: workspaceGroup.right
                            anchors.leftMargin: Config.Theme.moduleSpacing
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: clock.implicitWidth

                            QsModules.Clock {
                                id: clock
                                screenWidth: modelData.width

                                anchors.centerIn: parent
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
