import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as QsServices

Item {
    id: root
    property string fontFamily: "JetBrainsMono Nerd Font"
    property var barWindow

    property color colBg: "#13151A"
    property color colFg: "#d4c5b0"

    readonly property var brightness: QsServices.Brightness
    readonly property bool isHovered: mouseArea.containsMouse

    readonly property int percentage: brightness ? brightness.percentage || 0 : 0

    visible: brightness.supported

    implicitWidth: brightnessRow.implicitWidth || 0
    implicitHeight: brightnessRow.implicitHeight || 0

    RowLayout {
        id: brightnessRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: percentage + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
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
            color: isHovered ? "#7EA3CC" : colFg
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onWheel: wheel => {
            if (!brightness) return

            if (wheel.angleDelta.y > 0)
                brightness.increaseBrightness()
            else
                brightness.decreaseBrightness()
        }
    }
}