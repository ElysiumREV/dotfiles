import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property var window

    readonly property color colFg: "#f8f8f2"
    readonly property color colMuted: "#75715e"
    readonly property color colAccent: "#66d9ef"
    readonly property color colSurface: "#2d2d29"

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

                        Image {
                            id: image
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 16
                            sourceSize.height: 16
                            source: modelData.iconPixmap?.[0]?.toString() ?? ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon || "•"
                            font.pixelSize: 14
                            color: root.colFg
                            visible: image.status !== Image.Ready
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
