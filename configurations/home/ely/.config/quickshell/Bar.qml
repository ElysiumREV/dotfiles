import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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

            property color colBg: "#1d2021"
            property color colFg: "#ebdbb2"
            property color colMuted: "#3c3836"
            property color colCyan: "#8ec07c"
            property color colBlue: "#83a598"
            property color colYellow: "#fabd2f"
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 14

            property bool isFullscreen: false

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30
            color: colBg

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: isFullscreen ? 0 : implicitHeight
            WlrLayershell.layer: isFullscreen ? WlrLayer.Bottom : WlrLayer.Top

            Timer {
                interval: 200
                running: Hyprland !== null
                repeat: true

                onTriggered: {
                    if (!Hyprland)
                        return;
                    const win = Hyprland.activeWindow;
                    if (!win || !win.mapped) {
                        isFullscreen = false;
                        return;
                    }

                    const screenGeo = screen.geometry;

                    const coversScreen = win.at.x <= screenGeo.x && win.at.y <= screenGeo.y && win.size.width >= screenGeo.width && win.size.height >= screenGeo.height;

                    isFullscreen = win.fullscreen || coversScreen;
                }
            }

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
