import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

Variants {
    id: root

    // Defaults keep this component usable as a standalone configuration too.
    property color backgroundColor: "#141218"
    property color buttonColor: "#211f26"
    property color buttonHoverColor: "#4f378b"
    property color textColor: "#e6e0e9"
    property color borderColor: "#49454f"
    property real backgroundOpacity: 0.76
    property real gridScale: 0.75
    property real iconScale: 0.25
    property int textSize: 20
    property int borderWidth: 1
    property bool standalone: true

    default property list<LogoutButton> buttons
    model: Quickshell.screens

    function dismiss() {
        if (standalone)
            Qt.quit()
        else
            Services.WindowControl.logoutVisible = false
    }

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData
            screen: modelData
            visible: root.standalone || Services.WindowControl.logoutVisible
            focusable: visible
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None
            color: "transparent"
            BackgroundEffect.blurRegion: Region {
                item: panel.contentItem
            }

            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }

            contentItem {
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismiss()
                        return
                    }

                    for (let i = 0; i < root.buttons.length; i++) {
                        const button = root.buttons[i]
                        if (event.key === button.keybind) {
                            button.exec()
                            root.dismiss()
                            return
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(
                    root.backgroundColor.r,
                    root.backgroundColor.g,
                    root.backgroundColor.b,
                    root.backgroundOpacity
                )

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dismiss()
                }
            }

            Grid {
                id: buttonGrid
                anchors.centerIn: parent
                width: Math.min(parent.width * root.gridScale, 1100)
                height: Math.min(parent.height * root.gridScale, 680)
                columns: 3
                z: 1

                Repeater {
                    model: root.buttons

                    delegate: Rectangle {
                        required property LogoutButton modelData

                        width: buttonGrid.width / buttonGrid.columns
                        height: buttonGrid.height / Math.max(1, Math.ceil(root.buttons.length / buttonGrid.columns))
                        radius: 16
                        color: buttonMouse.containsMouse ? root.buttonHoverColor : root.buttonColor
                        border.color: root.borderColor
                        border.width: root.borderWidth

                        Column {
                            anchors.centerIn: parent
                            spacing: 16

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: Qt.resolvedUrl("icons/" + modelData.icon + ".png")
                                width: Math.min(buttonGrid.width / buttonGrid.columns, heightCell) * root.iconScale
                                height: width
                                fillMode: Image.PreserveAspectFit
                                smooth: true

                                property real heightCell: buttonGrid.height / Math.max(1, Math.ceil(root.buttons.length / buttonGrid.columns))
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pointSize: root.textSize
                                color: root.textColor
                            }
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.exec()
                                root.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}
