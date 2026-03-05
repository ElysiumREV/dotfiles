import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as QsServices

Item {
    id: root

    property var barWindow

    readonly property color gruvboxBg: "#1d2021"
    readonly property color gruvboxFg: "#ebdbb2"
    readonly property color gruvboxGray: "#ebdbb2"
    readonly property color gruvboxOrange: "#d65d0e"
    readonly property color gruvboxYellow: "#d79921"

    readonly property var brightness: QsServices.Brightness
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property int percentage: brightness?.percentage ?? 0

    implicitWidth: brightnessRow.implicitWidth
    implicitHeight: brightnessRow.implicitHeight

    RowLayout {
        id: brightnessRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: percentage + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.Regular
            color: gruvboxGray
        }

        Text {
            text: {
                if (percentage >= 75) return "󰃠"
                if (percentage >= 50) return "󰃟"
                if (percentage >= 25) return "󰃞"
                return "󰃝"
            }

            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (isHovered) return gruvboxOrange
                if (percentage >= 75) return gruvboxYellow
                return gruvboxFg
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0 && percentage < 100)
                brightness.increaseBrightness()
            else if (wheel.angleDelta.y < 0 && percentage > 0)
                brightness.decreaseBrightness()
        }
    }
}
