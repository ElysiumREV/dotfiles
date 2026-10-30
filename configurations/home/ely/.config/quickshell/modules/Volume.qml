import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Config
import "../services" as QsServices

Item {
    id: root

    property var barWindow
    property bool groupHighlighted: false
    signal requestMenu()

    readonly property var volume: QsServices.Volume
    readonly property bool isHovered: mouseArea.containsMouse || root.activeFocus
    readonly property int percentage: volume?.percentage ?? 0
    readonly property bool muted: volume?.effectivelyMuted ?? true
    readonly property string icon: {
        if (muted || percentage <= 0)
            return "volume_off";
        if (percentage < 35)
            return "volume_down";
        return "volume_up";
    }

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: Config.Theme.moduleHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: "Controles de áudio, " + percentage + (muted ? " por cento, silenciado" : " por cento")

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.requestMenu()
            event.accepted = true
        }
    }

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
            color: root.groupHighlighted ? Config.Theme.colOnHighlightContainer : Config.Theme.colFg
            visible: !root.muted
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: volumeIcon
            Layout.alignment: Qt.AlignVCenter
            text: root.icon
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            verticalAlignment: Text.AlignVCenter

            color: {
                if (root.groupHighlighted) return Config.Theme.colOnHighlightContainer
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

        onClicked: root.requestMenu()

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                volume.increaseVolume()
            } else {
                volume.decreaseVolume()
            }
        }
    }
}
