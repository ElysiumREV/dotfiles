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

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: 30

    RowLayout {
        id: volumeRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            id: volumeText
            Layout.alignment: Qt.AlignVCenter
            text: root.percentage + "%"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.Normal
            color: colFg
            visible: !root.muted
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: volumeIcon
            Layout.alignment: Qt.AlignVCenter
            text: root.icon
            font.family: root.fontFamily
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter

            color: {
                if (root.percentage <= 0) return colDisabled
                if (root.muted) return colDisabled
                if (root.isHovered) return colHighlight
                if (root.percentage >= 75) return colYellow
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
