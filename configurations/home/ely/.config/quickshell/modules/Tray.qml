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
                id: trayItem

                required property var modelData
                readonly property bool highlighted: mouseArea.containsMouse || activeFocus

                width: Config.Theme.trayItemSize
                height: Config.Theme.trayItemSize
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: modelData.tooltipTitle || modelData.title || modelData.id || "Tray item"

                // Items that only provide a menu (onlyMenu) open it on a left click too.
                function primaryAction() {
                    if (modelData.onlyMenu && modelData.hasMenu)
                        openMenu();
                    else
                        modelData.activate();
                }

                function openMenu() {
                    if (modelData.hasMenu)
                        menuLoader.activeAsync = true;
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        primaryAction();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Menu
                            || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
                        openMenu();
                        event.accepted = true;
                    }
                }

                LazyLoader {
                    id: menuLoader

                    QsMenuAnchor {
                        menu: trayItem.modelData.menu

                        // Anchored to the clicked icon, not to the whole tray.
                        anchor {
                            item: trayItem
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
                    color: trayItem.highlighted ? Config.Theme.alpha(Config.Theme.colTextSec, 0.18) : "transparent"
                    border.width: trayItem.activeFocus ? 1 : 0
                    border.color: Config.Theme.colHighlight
                }

                Loader {
                    id: loader

                    anchors.fill: parent

                    sourceComponent: Image {
                        source: trayItem.modelData.icon
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

                    // Initial of the item name; a full id would overflow the 18 px slot.
                    Text {
                        anchors.fill: parent
                        text: (trayItem.modelData.title || trayItem.modelData.id || "•").charAt(0).toUpperCase()
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        font.bold: true
                        color: Config.Theme.colFg
                    }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton)
                            trayItem.primaryAction();
                        else if (mouse.button === Qt.MiddleButton)
                            trayItem.modelData.secondaryActivate();
                        else
                            trayItem.openMenu();
                    }
                    // scroll() takes whole steps; touchpads send small deltas, so accumulate.
                    property real pendingScroll: 0
                    onWheel: wheel => {
                        const horizontal = wheel.angleDelta.y === 0;
                        pendingScroll += horizontal ? wheel.angleDelta.x : wheel.angleDelta.y;
                        const steps = Math.trunc(pendingScroll / 120);
                        if (steps !== 0) {
                            pendingScroll -= steps * 120;
                            trayItem.modelData.scroll(steps, horizontal);
                        }
                    }
                }
            }
        }
    }
}
