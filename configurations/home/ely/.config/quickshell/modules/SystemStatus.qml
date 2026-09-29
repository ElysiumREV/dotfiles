import Quickshell
import QtQuick
import QtQuick.Layouts
import ".." as Config
import "../services" as Services

Item {
    id: root

    property real screenWidth: 0
    readonly property real popupWidth: 380

    implicitHeight: Config.Theme.moduleHeight
    implicitWidth: rowLayout.implicitWidth

    function popupPosition(width) {
        const point = root.QsWindow.mapFromItem(root, (root.width - width) / 2, root.height)
        return {
            x: Math.max(0, Math.min(point.x, Math.max(0, root.screenWidth - width)))
        }
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleSpacing

        RowLayout {
            spacing: Config.Theme.moduleTightSpacing

            Text {
                text: "developer_board"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                color: Config.Theme.colHighlight
            }

            Text {
                text: Services.SystemStats.cpuUsage + "%"
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                color: Config.Theme.colFg
            }
        }

        Rectangle {
            width: Config.Theme.separatorWidth
            height: Config.Theme.separatorHeight
            color: Config.Theme.colMuted
            radius: Config.Theme.separatorRadius
        }

        RowLayout {
            spacing: Config.Theme.moduleTightSpacing

            Text {
                text: "memory"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                color: Config.Theme.colHighlight
            }

            Text {
                text: Services.SystemStats.memoryUsage + "%"
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                color: Config.Theme.colFg
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (usagePopup.visible)
                usagePopup.visible = false
            else
                usagePopup.openPopup()
        }
    }

    SystemUsagePopup {
        id: usagePopup
        positionProvider: root.popupPosition
    }
}
