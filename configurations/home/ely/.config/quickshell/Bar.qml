import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "modules"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: root

            required property var modelData
            screen: modelData

            property color colBg: "#272822"
            property color colFg: "#f8f8f2"
            property color colMuted: "#75715e"
            property color colCyan: "#66d9ef"
            property color colBlue: "#66d9ef"
            property color colYellow: "#e6db74"
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 14

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30
            color: colBg

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: implicitHeight
            WlrLayershell.layer: WlrLayer.Top

            Rectangle {
                anchors.fill: parent
                color: colBg

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    SystemStatus {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Tray {
                            anchors.verticalCenter: parent.verticalCenter
                            window: root
                        }

                        Volume {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Brightness {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Battery {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Clock {
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Workspaces {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
