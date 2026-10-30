import QtQuick
import QtQuick.Controls
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
    property real backgroundOpacity: 0.94
    property real gridScale: 0.78
    property real iconScale: 0.34
    property int textSize: 16
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
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

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

            Column {
                id: sessionContent
                anchors.centerIn: parent
                width: Math.min(parent.width * root.gridScale, 900)
                spacing: 28
                z: 1

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Sessão"
                        color: root.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 30
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Use as setas para navegar · Enter para selecionar · Esc para cancelar"
                        color: root.textColor
                        opacity: 0.72
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: root.textSize
                    }
                }

                Grid {
                    id: buttonGrid
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 3
                    spacing: 14

                    Repeater {
                        id: buttonRepeater
                        model: root.buttons

                        delegate: Button {
                            id: tile
                            required property LogoutButton modelData
                            required property int index

                            readonly property real diameter: Math.min(
                                132, (sessionContent.width - buttonGrid.spacing * 2) / 3,
                                (panel.height - 210) / Math.max(1, Math.ceil(root.buttons.length / 3))
                            )
                            width: diameter
                            height: diameter
                            activeFocusOnTab: true
                            onClicked: {
                                modelData.exec()
                                root.dismiss()
                            }
                            Keys.onPressed: event => {
                                let targetIndex = index;
                                const rowStart = Math.floor(index / buttonGrid.columns) * buttonGrid.columns;
                                const rowEnd = Math.min(rowStart + buttonGrid.columns - 1, buttonRepeater.count - 1);

                                if (event.key === Qt.Key_Left)
                                    targetIndex = Math.max(rowStart, index - 1);
                                else if (event.key === Qt.Key_Right)
                                    targetIndex = Math.min(rowEnd, index + 1);
                                else if (event.key === Qt.Key_Up && index - buttonGrid.columns >= 0)
                                    targetIndex = index - buttonGrid.columns;
                                else if (event.key === Qt.Key_Down && index + buttonGrid.columns < buttonRepeater.count)
                                    targetIndex = index + buttonGrid.columns;
                                else if (event.key === modelData.keybind) {
                                    modelData.exec()
                                    root.dismiss()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    root.dismiss()
                                    event.accepted = true
                                }

                                if (targetIndex !== index) {
                                    buttonRepeater.itemAt(targetIndex)?.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }
                            background: Rectangle {
                                radius: tile.activeFocus || tile.hovered ? width / 2 : 36
                                color: tile.activeFocus || tile.hovered
                                    ? root.buttonHoverColor : root.buttonColor
                                border.color: tile.activeFocus ? root.textColor : root.borderColor
                                border.width: tile.activeFocus ? Math.max(2, root.borderWidth) : root.borderWidth
                                Behavior on radius {
                                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
                                }
                            }

                            contentItem: Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: Qt.resolvedUrl("icons/" + modelData.icon + ".png")
                                    width: tile.width * root.iconScale
                                    height: width
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.text
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pointSize: root.textSize
                                    color: root.textColor
                                }
                            }
                        }
                    }
                }
            }

            onVisibleChanged: {
                if (visible)
                    Qt.callLater(() => buttonRepeater.itemAt(0)?.forceActiveFocus())
            }
        }
    }
}
