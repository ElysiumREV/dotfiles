import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".." as Config

Item {
    id: root

    property string formattedTime:
        clock.currentDate.toLocaleTimeString(Qt.locale(), "HH:mm")
    property string formattedDate:
        clock.currentDate.toLocaleDateString(Qt.locale(), "ddd, dd MMM")
    property real screenWidth: 0

    readonly property color accentColor:
        calendarMouse.containsMouse
        ? Config.Theme.colHighlight
        : Config.Theme.colFg


    implicitWidth: clockRow.implicitWidth
    implicitHeight: Config.Theme.moduleHeight

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.formattedTime
            color: root.accentColor
            font {
                family: Config.Theme.fontFamily
                pixelSize: Config.Theme.fontSize
            }
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "•"
            color: root.accentColor
            font {
                family: Config.Theme.fontFamily
                pixelSize: Config.Theme.fontSizeSmall
            }
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.formattedDate
            color: root.accentColor
            font {
                family: Config.Theme.fontFamily
                pixelSize: Config.Theme.fontSizeSmall
            }
            verticalAlignment: Text.AlignVCenter
        }
    }

    CalendarPopup {
        id: calendarPopup
        currentDate: clock.currentDate
        positionProvider: popupWidth => {
            const position = root.QsWindow.mapFromItem(
                root,
                (root.implicitWidth - popupWidth) / 2,
                root.implicitHeight
            )
            return {
                "x": Math.max(0, Math.min(position.x, root.screenWidth - popupWidth)),
                "y": position.y
            }
        }
    }

    MouseArea {
        id: calendarMouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (calendarPopup.visible)
                calendarPopup.visible = false;
            else
                calendarPopup.openCalendar();
        }
    }

    Scope {
        id: clock
        property date currentDate: new Date()

        Timer {
            interval: 15000
            running: true
            repeat: true
            onTriggered: clock.currentDate = new Date()
        }
    }
}
