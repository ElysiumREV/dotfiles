import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".." as Config
import "../services" as Services

Item {
    id: root

    required property var targetScreen
    property string formattedTime:
        clock.currentDate.toLocaleTimeString(Qt.locale(), "HH:mm")
    property string formattedDate:
        screenWidth <= Config.Theme.barCompactWidthThreshold
            ? clock.currentDate.toLocaleDateString(Qt.locale(), "dd/MM")
            : clock.currentDate.toLocaleDateString(Qt.locale(), "ddd, dd MMM")
    property real screenWidth: 0
    property bool showDate: true

    readonly property color accentColor:
        calendarMouse.containsMouse || root.activeFocus
        ? Config.Theme.colHighlight
        : Config.Theme.colFg


    implicitWidth: clockRow.implicitWidth
    implicitHeight: Config.Theme.moduleHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: "Open calendar, " + formattedTime

    // The calendar lives in the Arch Menu; the clock opens it expanded.
    function openCalendar() {
        Services.Notifications.toggleCalendar(Hyprland.monitorFor(root.targetScreen));
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.openCalendar();
            event.accepted = true;
        }
    }

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: Config.Theme.spaceXs
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
            visible: root.showDate
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
            visible: root.showDate
            text: root.formattedDate
            color: root.accentColor
            font {
                family: Config.Theme.fontFamily
                pixelSize: Config.Theme.fontSizeSmall
            }
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: calendarMouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.openCalendar()
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
