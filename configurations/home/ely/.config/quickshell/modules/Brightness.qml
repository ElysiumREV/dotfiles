import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as QsServices

Item {
    id: root

    property var barWindow

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
            font.weight: Font.Normal
            color: colFg
        }

        Text {
            text: {
                if (percentage >= 75) return "󰃠"
                if (percentage >= 50) return "󰃟"
                if (percentage >= 25) return "󰃞"
                return "󰃝"
            }

            font.family: root.fontFamily
            font.pixelSize: 14

            color: {
                if (isHovered) return colBlue
                if (percentage >= 75) return colYellow
                return colFg
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
