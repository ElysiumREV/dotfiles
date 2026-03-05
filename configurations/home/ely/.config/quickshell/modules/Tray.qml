import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property var window

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        spacing: 6

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property var modelData

                width: 16
                height: 16

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
                            font.pixelSize: 16
                            color: "#ffffff"
                            visible: image.status !== Image.Ready
                        }
                    }
                }

                MouseArea {
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