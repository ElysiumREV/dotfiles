import ".." as Config
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

        spacing: Config.Theme.moduleSpacing

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property var modelData
                property bool hovered: mouseArea.containsMouse

                width: Config.Theme.trayItemSize
                height: Config.Theme.trayItemSize

                LazyLoader {
                    id: menuLoader

                    QsMenuAnchor {
                        menu: modelData.menu

                        anchor {
                            item: root
                            gravity: Edges.Bottom
                            edges: Edges.Bottom
                        }
                    }

                    onActiveChanged: if (active && item) item.open()
                }

                Connections {
                    target: menuLoader.item
                    function onClosed() {
                        menuLoader.activeAsync = false
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + Config.Theme.trayHoverPadding
                    height: parent.height + Config.Theme.trayHoverPadding
                    radius: Config.Theme.trayHoverRadius
                    color: hovered ? Config.Theme.alpha(Config.Theme.colTextSec, 0.18) : "transparent"
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
                                loader.sourceComponent = fallbackComponent;
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
                            modelData.activate();
                        } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            menuLoader.activeAsync = true;
                        }
                    }
                }
            }
        }
    }
}
