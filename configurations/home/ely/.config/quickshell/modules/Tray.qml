import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../Theme.qml" as QsTheme

Item {
    id: root

    property var window

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
                            font.family: QsTheme.fontFamily
                            font.pixelSize: QsTheme.fontSize
                            color: QsTheme.colFg
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true

                    onPressed: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            const pt = mapToItem(root.window.contentItem, Qt.point(width / 2, height))
                            modelData.display(root.window, pt.x, pt.y)
                        }
                    }
                }
            }
        }
    }
}
