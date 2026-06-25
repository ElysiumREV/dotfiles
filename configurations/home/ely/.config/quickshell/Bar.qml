import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "." as Config
import "modules" as QsModules
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

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Config.Theme.moduleSpacing

                        QsModules.SystemStatus {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QsModules.Media {
                            anchors.verticalCenter: parent.verticalCenter
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

                        QsModules.Volume {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Só mostra Brightness em dispositivos com suporte (não desktop)
                        //QsModules.Brightness {
                        //  anchors.verticalCenter: parent.verticalCenter
                        //}

                        // Só mostra Battery quando há bateria disponível
                        QsModules.Battery {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !!UPower.displayDevice && UPower.displayDevice.isPresent
                        }

                        QsModules.Clock {
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    QsModules.Workspaces {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
