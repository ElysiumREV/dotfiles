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

    readonly property color colFg: "#f8f8f2"
    readonly property color colMuted: "#75715e"
    readonly property color colBlue: "#66d9ef"
    readonly property color colYellow: "#e6db74"

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
            color: colFg
            visible: !root.muted
        }

        Text {
            id: volumeIcon
            text: root.icon
            font.family: "Material Design Icons"
            font.pixelSize: 14

            color: {
                if (root.muted) return colMuted
                if (root.isHovered) return colBlue
                if (root.percentage >= 66) return colYellow
                return colFg
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
