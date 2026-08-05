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

    implicitWidth: clockRow.implicitWidth
    implicitHeight: Config.Theme.moduleHeight

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.formattedTime
            color: Config.Theme.colFg
            font {
                family: Config.Theme.fontFamily
                pixelSize: Config.Theme.fontSize
            }
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "•"
            color: Config.Theme.colFg
            font {
                family: Config.Theme.fontFamily
                pixelSize: Config.Theme.fontSizeSmall
            }
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.formattedDate
            color: Config.Theme.colFg
            font {
                family: Config.Theme.fontFamily
                pixelSize: Config.Theme.fontSizeSmall
            }
            verticalAlignment: Text.AlignVCenter
        }
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
