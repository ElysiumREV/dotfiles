import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property var window

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

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property var modelData

                width: 18
                height: 18

                property bool hovered: mouseArea.containsMouse

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 8
                    height: parent.height + 8
                    radius: 6
                    color: hovered ? Qt.rgba(139/255, 164/255, 176/255, 0.18) : "transparent"
                }

                Loader {
                    id: loader
                    anchors.fill: parent

                    sourceComponent: Image {
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: 32
                        sourceSize.height: 32

                        onStatusChanged: {
                            if (status === Image.Error)
                                loader.sourceComponent = fallbackComponent
                        }
                    }
                }

                Component {
                    id: fallbackComponent

                    Item {
                        anchors.fill: parent

                        Text {
                            anchors.centerIn: parent
                            text: modelData.id || modelData.name || "•"
                            font.family: root.fontFamily
                            font.pixelSize: 14
                            color: root.colFg
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            const global = mapToItem(root.window.contentItem, width / 2, height)
                            modelData.display(root.window, global.x, global.y)
                        }
                    }
                }
            }
        }
    }
}
