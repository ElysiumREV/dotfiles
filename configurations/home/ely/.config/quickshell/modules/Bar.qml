import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "../." as Config
import "." as QsModules
import "services" as QsServices

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: root

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            margins.top: Config.Theme.barInset
            margins.left: Config.Theme.barInset
            margins.right: Config.Theme.barInset
            margins.bottom: Config.Theme.barInset

            implicitHeight: Config.Theme.barHeight
            color: "transparent"

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: implicitHeight
            WlrLayershell.layer: WlrLayer.Bottom

            Rectangle {
                id: barSurface

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: Config.Theme.barHeight
                radius: Config.Theme.barRadius
                color: Qt.rgba(Config.Theme.colBg.r, Config.Theme.colBg.g, Config.Theme.colBg.b, 0.88)
                clip: true

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: Config.Theme.barContentMargin
                    anchors.rightMargin: Config.Theme.barContentMargin

                    Text {
                        id: archPlaceholder
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: Config.Theme.colHighlight
                        font {
                            family: Config.Theme.fontFamily
                            pixelSize: 20
                        }
                        verticalAlignment: Text.AlignVCenter
                    }

                    ArchMenu {
                        id: archMenu
                        positionProvider: popupWidth => {
                            const position = archPlaceholder.QsWindow.mapFromItem(
                                archPlaceholder, 0, 0
                            );
                            return { x: Math.max(Config.Theme.barContentMargin, position.x), y: position.y };
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

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Config.Theme.moduleSpacing

                        QsModules.Tray {
                            anchors.verticalCenter: parent.verticalCenter
                            window: root
                        }

                        Rectangle {
                            width: deviceIndicators.implicitWidth + 12
                            height: 28
                            radius: 10
                            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.12)

                            Row {
                                id: deviceIndicators
                                anchors.centerIn: parent
                                spacing: Config.Theme.moduleSpacing

                                QsModules.Volume {
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Só mostra Battery quando há bateria disponível.
                                QsModules.Battery {
                                    id: batteryItem
                                    anchors.verticalCenter: parent.verticalCenter
                        }
                        // Close Row
                        }
                        QsModules.BatteryMenu {
                            id: batteryMenu
                            positionProvider: popupWidth => {
                                const position = batteryItem.QsWindow.mapFromItem(batteryItem, 0, 0);
                                return { x: Math.max(Config.Theme.barContentMargin, position.x), y: position.y };
                            }
                        }
                        }

                    }

                    Rectangle {
                        id: workspaceGroup
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: workspaces.implicitWidth + 12
                        height: 28
                        radius: 10
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.12)

                        QsModules.Workspaces {
                            id: workspaces
                            anchors.centerIn: parent
                        }
                    }

                    Rectangle {
                        id: mediaGroup
                        anchors.right: workspaceGroup.left
                        anchors.rightMargin: Config.Theme.moduleSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        width: media.implicitWidth + 12
                        height: 28
                        radius: 10
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.12)

                        QsModules.Media {
                            id: media
                            anchors.centerIn: parent
                        }
                    }

                    Rectangle {
                        anchors.right: mediaGroup.left
                        anchors.rightMargin: Config.Theme.moduleSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        width: systemStatus.implicitWidth + 12
                        height: 28
                        radius: 10
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.12)

                        QsModules.SystemStatus {
                            id: systemStatus
                            anchors.centerIn: parent
                        }
                    }

                    Rectangle {
                        anchors.left: workspaceGroup.right
                        anchors.leftMargin: Config.Theme.moduleSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        width: clock.implicitWidth + 12
                        height: 28
                        radius: 10
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.12)

                        QsModules.Clock {
                            id: clock
                            anchors.centerIn: parent
                        }
                    }
                }
            }
        }
    }
}
