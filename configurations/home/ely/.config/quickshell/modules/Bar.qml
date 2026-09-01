import "." as QsModules
import "../." as Config
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland

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
                        Text {
                            id: archPlaceholder

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: Config.Theme.colHighlight
                            verticalAlignment: Text.AlignVCenter

                            font {
                                family: Config.Theme.fontFamily
                                pixelSize: 20
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
                            spacing: Config.Theme.moduleSpacing

                            QsModules.Tray {
                                anchors.verticalCenter: parent.verticalCenter
                                window: root
                            }

                            QsModules.ModuleGroup {
                                contentWidth: deviceIndicators.implicitWidth

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

                                }

                            }

                            QsModules.BatteryMenu {
                                id: batteryMenu

                                positionProvider: (popupWidth) => {
                                    const position = batteryItem.QsWindow.mapFromItem(batteryItem, 0, 0);
                                    let desiredX = Math.max(Config.Theme.barContentMargin, position.x);
                                    const screenWidth = modelData.width;
                                    const maxX = screenWidth - popupWidth;
                                    const clampedX = Math.min(Math.max(desiredX, 0), maxX);
                                    return {
                                        "x": clampedX,
                                        "y": position.y
                                    };
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

                            anchors.right: workspaceGroup.left
                            anchors.rightMargin: Config.Theme.moduleSpacing
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: media.implicitWidth

                            QsModules.Media {
                                id: media

                                anchors.centerIn: parent
                            }

                        }

                        /*
                         * =================================================
                         * SYSTEM STATUS
                         * =================================================
                         */
                        QsModules.ModuleGroup {
                            anchors.right: mediaGroup.left
                            anchors.rightMargin: Config.Theme.moduleSpacing
                            anchors.verticalCenter: parent.verticalCenter
                            contentWidth: systemStatus.implicitWidth

                            QsModules.SystemStatus {
                                id: systemStatus

                                anchors.centerIn: parent
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
