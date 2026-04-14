import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "modules" as QsModules
import "services" as QsServices

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: root

            required property var modelData
            screen: modelData

            property color colBg: "#13151A"
            property color colFg: "#d4c5b0"
            property color colText: "#F0F1F5"
            property color colTextSec: "#B8BCCA"
            property color colMuted: "#7C8291"
            property color colDisabled: "#505563"
            property color colHighlight: "#A08EC4"
            property color colBlue: "#7EA3CC"
            property color colYellow: "#e6c97a"
            property color colRed: "#C47A7A"
            property color colOrange: "#C4956A"
            property color colGreen: "#7EBD9B"
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 14

            property int barInset: 6
            property int barHeight: 30

            anchors {
                top: true
                left: true
                right: true
            }

            margins.top: barInset
            margins.left: barInset
            margins.right: barInset

            implicitHeight: barHeight
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
                height: barHeight
                radius: 10
                color: Qt.rgba(colBg.r, colBg.g, colBg.b, 0.88)
                clip: true

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        QsModules.SystemStatus {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QsModules.Mpd {
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        QsModules.Tray {
                            anchors.verticalCenter: parent.verticalCenter
                            window: root
                        }

                        QsModules.Volume {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Só mostra Brightness em dispositivos com suporte (não desktop)
                        QsModules.Brightness {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: QsModules.Brightness.supported
                        }

                        // Só mostra Battery quando há bateria disponível
                        QsModules.Battery {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: UPower.displayDevice !== null
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
