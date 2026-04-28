import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../Theme.qml" as QsTheme

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
        color: "#d4c5b0"
        font {
            family: "JetBrainsMono Nerd Font"
            pixelSize: 13
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
