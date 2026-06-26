import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".." as Config

ShellRoot {
    id: root

    readonly property list<QtObject> buttons: [
        QtObject {
            readonly property string text: "Lock"
            readonly property string icon: "lock"
            readonly property var keybind: Qt.Key_L
            readonly property string command: "hyprlock"
        },
        QtObject {
            readonly property string text: "Logout"
            readonly property string icon: "logout"
            readonly property var keybind: Qt.Key_E
            readonly property string command: "hyprshutdown --post-cmd 'hyprctl dispatch hl.dsp.exit()'"
        },
        QtObject {
            readonly property string text: "Shutdown"
            readonly property string icon: "shutdown"
            readonly property var keybind: Qt.Key_S
            readonly property string command: "hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"
        },
        QtObject {
            readonly property string text: "Reboot"
            readonly property string icon: "reboot"
            readonly property var keybind: Qt.Key_R
            readonly property string command: "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"
        }
    ]

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: w
            property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key == Qt.Key_Escape) Qt.quit();
                    else {
                        for (let i = 0; i < root.buttons.length; i++) {
                            let btn = root.buttons[i];
                            if (event.key == btn.keybind) {
                                var p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
                                p.command = ["sh", "-c", btn.command]
                                p.startDetached()
                                Qt.quit();
                            }
                        }
                    }
                }
            }

            anchors { top: true; left: true; bottom: true; right: true }

            Rectangle {
                color: Config.Theme.colWlogoutBg
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.quit()

                    GridLayout {
                        anchors.centerIn: parent
                        width: parent.width * Config.Theme.wlogoutGridScale
                        height: parent.height * Config.Theme.wlogoutGridScale
                        columns: 2
                        columnSpacing: 0
                        rowSpacing: 0

                        Repeater {
                            model: root.buttons
                            delegate: Rectangle {
                                required property QtObject modelData

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                color: ma.containsMouse ? Config.Theme.colWlogoutButtonHover : Config.Theme.colWlogoutButton
                                border.color: Config.Theme.colBorder
                                border.width: ma.containsMouse ? 0 : Config.Theme.wlogoutBorderWidth

                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
                                        p.command = ["sh", "-c", modelData.command]
                                        p.startDetached()
                                        Qt.quit();
                                    }
                                }

                                Image {
                                    id: icon
                                    anchors.centerIn: parent
                                    source: Qt.resolvedUrl(`icons/${modelData.icon}.png`)
                                    width: parent.width * Config.Theme.wlogoutIconScale
                                    height: parent.width * Config.Theme.wlogoutIconScale
                                }

                                Text {
                                    anchors {
                                        top: icon.bottom
                                        topMargin: Config.Theme.wlogoutTextTopMargin
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    text: modelData.text
                                    font.pointSize: Config.Theme.wlogoutTextSize
                                    color: Config.Theme.colWlogoutText
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
