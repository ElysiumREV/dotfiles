import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import ".." as Config

Item {
    id: root

    property var window

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        spacing: Config.Theme.moduleSpacing

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property var modelData

                width: Config.Theme.trayItemSize
                height: Config.Theme.trayItemSize

                property bool hovered: mouseArea.containsMouse

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + Config.Theme.trayHoverPadding
                    height: parent.height + Config.Theme.trayHoverPadding
                    radius: Config.Theme.trayHoverRadius
                    color: hovered ? Qt.rgba(139/255, 164/255, 176/255, 0.18) : "transparent"
                }

                Loader {
                    id: loader
                    anchors.fill: parent

                    sourceComponent: Image {
                        source: modelData.icon
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: Config.Theme.trayIconSourceSize
                        sourceSize.height: Config.Theme.trayIconSourceSize

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
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSize
                            color: Config.Theme.colFg
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
                            const pt = mapToItem(root.window.contentItem, Qt.point(width / 2, height))
                            modelData.display(root.window, pt.x, pt.y)
                        }
                    }
                }
            }
        }
    }
}
