import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as QsServices

Item {
    id: root

    property var barWindow

    readonly property var volume: QsServices.Volume
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property int percentage: volume?.percentage ?? 0
    readonly property bool muted: volume?.muted ?? false
    readonly property string icon: volume?.icon ?? "󰕾"

    readonly property color gruvboxFg: "#ebdbb2"
    readonly property color gruvboxGray: "#a89984"
    readonly property color gruvboxOrange: "#d65d0e"
    readonly property color gruvboxYellow: "#fabd2f"

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: volumeRow
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: volumeText
            text: root.percentage + "%"
            font.family: "JetBrainsMono"
            font.pixelSize: 12
            font.weight: Font.Regular
            color: gruvboxFg
            visible: !root.muted
        }

        Text {
            id: volumeIcon
            text: root.icon
            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (root.muted) return gruvboxGray
                if (root.isHovered) return gruvboxOrange
                if (root.percentage >= 66) return gruvboxYellow
                return gruvboxFg
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: volume.toggleMute()

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                volume.increaseVolume()
            } else {
                volume.decreaseVolume()
            }
        }
    }
}
