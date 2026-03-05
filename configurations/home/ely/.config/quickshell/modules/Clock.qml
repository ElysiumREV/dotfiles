import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    // Theme
    property color colFg: "#ebdbb2"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14
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
        color: root.colFg
        font {
            family: root.fontFamily
            pixelSize: root.fontSize
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
