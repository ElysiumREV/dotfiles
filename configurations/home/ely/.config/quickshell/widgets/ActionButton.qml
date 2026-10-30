import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Config

Button {
    id: root

    required property string label
    required property string iconName
    property bool emphasized: false

    implicitWidth: actionRow.implicitWidth + 24
    implicitHeight: 38
    opacity: enabled ? 1 : 0.45
    activeFocusOnTab: true

    contentItem: RowLayout {
        id: actionRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.iconName
            color: root.emphasized || root.hovered || root.activeFocus
                ? Config.Theme.colOnHighlightContainer : Config.Theme.colFg
            font.family: "Material Symbols Rounded"
            font.pixelSize: 17
        }

        Text {
            text: root.label
            color: root.emphasized || root.hovered || root.activeFocus
                ? Config.Theme.colOnHighlightContainer : Config.Theme.colFg
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            font.bold: root.emphasized
        }
    }

    background: Rectangle {
        radius: Config.Theme.radiusControl
        color: root.emphasized || root.hovered || root.activeFocus
            ? Config.Theme.colHighlightContainer : Config.Theme.colSurface
        border.width: root.activeFocus ? 1 : 0
        border.color: Config.Theme.colHighlight
    }
}
