import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".." as Config

Item {
    id: root

    property string timeFormat: "dd MMM HH:mm"

    property string formattedTime: {
        const date = clock.currentDate;
        return date.toLocaleString(Qt.locale(), timeFormat);
    }

    implicitWidth: timeText.implicitWidth
    implicitHeight: timeText.implicitHeight

    Text {
        id: timeText
        text: root.formattedTime
        color: Config.Theme.colFg
        font {
            family: Config.Theme.fontFamily
            pixelSize: Config.Theme.fontSizeClock
        }
        verticalAlignment: Text.AlignVCenter
    }

    Scope {
        id: clock
        property date currentDate: new Date()

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.currentDate = new Date()
        }
    }
}
