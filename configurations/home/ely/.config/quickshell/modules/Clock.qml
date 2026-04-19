import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color colBg: "#13151A"
            property color colFg: "#d4c5b0"
            property color colText: "#F0F1F5"
            property color colTextSec: "#B8BCCA"
            property color colMuted: "#7C8291"
            property color colDisabled: "#505563"
            property color colHighlight: "#A08EC4"
            property color colBlue: "#7EA3CC"
            property color colYellow: "#e6c97a"
            property color colRed: "#C47A7A"
            property color colOrange: "#C4956A"
            property color colGreen: "#7EBD9B"
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
