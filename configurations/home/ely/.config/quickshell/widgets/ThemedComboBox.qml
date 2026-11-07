import QtQuick
import QtQuick.Controls
import ".." as Config

ComboBox {
    id: root

    // Text shown when nothing is selected (e.g. no devices available).
    property string emptyText: ""
    // The popup opens above the control by default (menus sit at the bottom of panels).
    property bool popupAbove: true
    property int popupMaxHeight: 220

    // Enter opens the list when it is closed (Qt only uses Space); when open, Qt selects the item.
    Keys.onReturnPressed: event => { if (!popup.visible) { popup.open(); event.accepted = true; } }
    Keys.onEnterPressed: event => { if (!popup.visible) { popup.open(); event.accepted = true; } }

    leftPadding: 9
    rightPadding: 9
    topPadding: 0
    bottomPadding: 0

    contentItem: Text {
        leftPadding: 0
        rightPadding: 24
        text: root.displayText || root.emptyText
        color: Config.Theme.colFg
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSizeSmall
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Config.Theme.radiusControl
        color: root.down || root.popup.visible
            ? Config.Theme.alpha(Config.Theme.colHighlight, 0.15)
            : Config.Theme.alpha(Config.Theme.colBg, 0.45)
        border.width: root.activeFocus ? 1 : 0
        border.color: Config.Theme.colHighlight
    }

    indicator: Text {
        x: root.width - width - 8
        y: (root.height - height) / 2
        text: root.popup.visible ? "expand_less" : "expand_more"
        color: root.popup.visible || root.activeFocus
            ? Config.Theme.colHighlight : Config.Theme.colTextSec
        font.family: "Material Symbols Rounded"
        font.pixelSize: Config.Theme.iconSizeSm
        verticalAlignment: Text.AlignVCenter
    }

    delegate: ItemDelegate {
        required property var modelData
        required property int index
        width: root.width - 8
        text: modelData
        highlighted: root.highlightedIndex === index
        padding: 9
        contentItem: Text {
            text: modelData
            color: parent.highlighted ? Config.Theme.colFg : Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: Config.Theme.radiusSmall
            color: parent.highlighted
                ? Config.Theme.alpha(Config.Theme.colHighlight, 0.2)
                : "transparent"
        }
    }

    popup: Popup {
        y: root.popupAbove ? -height - 5 : root.height + 5
        width: root.width
        padding: 4
        implicitHeight: Math.min(listView.contentHeight + topPadding + bottomPadding, root.popupMaxHeight)
        background: Rectangle {
            radius: Config.Theme.radiusControl + 2
            color: Config.Theme.colBg
            border.width: 1
            border.color: Config.Theme.colBorder
        }
        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
