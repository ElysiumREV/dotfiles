import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Config
import "../services" as QsServices

Item {
    id: root
    property var barWindow

    readonly property var brightness: QsServices.Brightness
    readonly property bool isHovered: mouseArea.containsMouse

    readonly property int percentage: brightness ? brightness.percentage || 0 : 0

    visible: brightness.supported

    implicitWidth: brightnessRow.implicitWidth || 0
    implicitHeight: brightnessRow.implicitHeight || 0

    RowLayout {
        id: brightnessRow
        anchors.centerIn: parent
        spacing: Config.Theme.moduleInnerSpacing

        Text {
            text: percentage + "%"
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            color: Config.Theme.colFg
        }

        Text {
            text: {
                if (percentage >= 75) return "󰃠"
                if (percentage >= 50) return "󰃟"
                if (percentage >= 25) return "󰃞"
                return "󰃝"
            }

            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSize
            color: isHovered ? Config.Theme.colBlue : Config.Theme.colFg
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
