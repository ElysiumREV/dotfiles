import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Config
import "../services" as QsServices

Item {
    id: root

    property var barWindow

    readonly property var volume: QsServices.Volume
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property int percentage: volume?.percentage ?? 0
    readonly property bool muted: volume?.muted ?? false
    readonly property string icon: volume?.icon ?? "󰕾"

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: Config.Theme.moduleHeight

    RowLayout {
        id: volumeRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleTightSpacing

        Text {
            id: volumeText
            Layout.alignment: Qt.AlignVCenter
            text: root.percentage + "%"
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            font.weight: Font.Normal
            color: Config.Theme.colFg
            visible: !root.muted
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: volumeIcon
            Layout.alignment: Qt.AlignVCenter
            text: root.icon
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSize
            verticalAlignment: Text.AlignVCenter

            color: {
                if (root.percentage <= 0) return Config.Theme.colDisabled
                if (root.muted) return Config.Theme.colDisabled
                if (root.isHovered) return Config.Theme.colHighlight
                if (root.percentage >= 75) return Config.Theme.colYellow
                return Config.Theme.colFg
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
