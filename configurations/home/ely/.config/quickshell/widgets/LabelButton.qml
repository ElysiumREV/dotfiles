import QtQuick
import QtQuick.Controls
import ".." as Config

Button {
    id: root

    property int labelFontSize: Config.Theme.fontSizeSmall
    property int cornerRadius: Config.Theme.radiusControl
    property int contentHorizontalPadding: 10
    property int contentVerticalPadding: 4
    property int labelAlignment: Text.AlignHCenter
    property color idleTextColor: Config.Theme.colFg
    property color hoverTextColor: Config.Theme.colOnHighlightContainer
    property color disabledTextColor: Config.Theme.colMuted
    property color idleBackgroundColor: "transparent"
    property color hoverBackgroundColor: Config.Theme.colHighlightContainer
    property bool outlineOnFocus: false

    activeFocusOnTab: true
    implicitWidth: label.implicitWidth + contentHorizontalPadding * 2
    implicitHeight: label.implicitHeight + contentVerticalPadding * 2

    contentItem: Text {
        id: label
        text: root.text
        color: !root.enabled ? root.disabledTextColor
            : ((root.hovered || root.activeFocus) ? root.hoverTextColor : root.idleTextColor)
        font.family: Config.Theme.fontFamily
        font.pixelSize: root.labelFontSize
        horizontalAlignment: root.labelAlignment
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: root.cornerRadius
        color: root.hovered || root.activeFocus
            ? root.hoverBackgroundColor : root.idleBackgroundColor
        border.width: root.outlineOnFocus && root.activeFocus ? 1 : 0
        border.color: Config.Theme.colHighlight
    }
}
