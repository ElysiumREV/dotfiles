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

    readonly property color tokyoFg: "#c0caf5"
    readonly property color tokyoMuted: "#565f89"
    readonly property color tokyoBlue: "#7aa2f7"
    readonly property color tokyoYellow: "#e0af68"

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: volumeRow
        anchors.centerIn: parent
        spacing: 3

        Text {
            id: volumeText
            text: root.percentage + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.Regular
            color: tokyoFg
            visible: !root.muted
        }

        Text {
            id: volumeIcon
            text: root.icon
            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (root.muted) return tokyoMuted
                if (root.isHovered) return tokyoBlue
                if (root.percentage >= 66) return tokyoYellow
                return tokyoFg
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