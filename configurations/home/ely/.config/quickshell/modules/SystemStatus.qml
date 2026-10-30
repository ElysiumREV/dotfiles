import Quickshell
import QtQuick
import QtQuick.Layouts
import ".." as Config
import "../services" as Services
import "../widgets" as Widgets
import "./PopupGeometry.js" as PopupGeometry

Item {
    id: root

    required property var targetScreen
    property real screenWidth: 0
    readonly property real popupWidth: PopupGeometry.widthForScreen(targetScreen, 380, 24)

    implicitHeight: Config.Theme.moduleHeight
    implicitWidth: rowLayout.implicitWidth
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: "Uso de recursos: CPU " + Services.SystemStats.cpuUsage
        + " por cento, memória " + Services.SystemStats.memoryUsage + " por cento"

    function togglePopup() {
        if (usagePopupLoader.activeAsync) {
            usagePopupLoader.item.visible = false
            usagePopupLoader.activeAsync = false
        } else {
            usagePopupLoader.activeAsync = true
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.togglePopup()
            event.accepted = true
        }
    }

    function popupPosition(width) {
        const point = root.QsWindow.mapFromItem(root, (root.width - width) / 2, root.height)
        return {
            x: Math.max(0, Math.min(point.x, Math.max(0, root.screenWidth - width)))
        }
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        RowLayout {
            spacing: 2

            Widgets.CircularProgressIcon {
                diameter: 26
                iconSize: 16
                iconName: "planner_review"
                progress: Services.SystemStats.cpuUsage / 100
                ringColor: Config.Theme.colHighlight
                iconColor: Config.Theme.colFg
            }

            Text {
                text: Services.SystemStats.cpuUsage
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                color: Config.Theme.colFg
            }
        }

        RowLayout {
            spacing: 2

            Widgets.CircularProgressIcon {
                diameter: 26
                iconSize: 16
                iconName: "memory"
                progress: Services.SystemStats.memoryUsage / 100
                ringColor: Config.Theme.colHighlight
                iconColor: Config.Theme.colFg
            }

            Text {
                text: Services.SystemStats.memoryUsage
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                color: Config.Theme.colFg
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }

    LazyLoader {
        id: usagePopupLoader

        SystemUsagePopup {
            targetScreen: root.targetScreen
            positionProvider: root.popupPosition
        }

        onActiveChanged: if (active && item) item.openPopup()
    }

    Connections {
        target: usagePopupLoader.item
        function onVisibleChanged() {
            if (target && !target.visible)
                usagePopupLoader.activeAsync = false
        }
    }
}
