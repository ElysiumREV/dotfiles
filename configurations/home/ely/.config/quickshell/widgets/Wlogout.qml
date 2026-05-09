import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    property color backgroundColor: "#e60c0c0c"
    property color buttonColor: "#1e1e1e"
    property color buttonHoverColor: "#3700b3"

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
                color: root.backgroundColor
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.quit()

                    GridLayout {
                        anchors.centerIn: parent
                        width: parent.width * 0.75
                        height: parent.height * 0.75
                        columns: 2
                        columnSpacing: 0
                        rowSpacing: 0

                        Repeater {
                            model: root.buttons
                            delegate: Rectangle {
                                required property QtObject modelData

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                color: ma.containsMouse ? root.buttonHoverColor : root.buttonColor
                                border.color: "black"
                                border.width: ma.containsMouse ? 0 : 1

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
                                    width: parent.width * 0.25
                                    height: parent.width * 0.25
                                }

                                Text {
                                    anchors {
                                        top: icon.bottom
                                        topMargin: 20
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                    text: modelData.text
                                    font.pointSize: 20
                                    color: "white"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
