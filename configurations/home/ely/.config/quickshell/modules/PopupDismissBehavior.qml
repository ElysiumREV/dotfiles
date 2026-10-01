import QtQuick

HoverHandler {
    id: root

    required property var popup
    property bool pointerEntered: false

    parent: popup.contentItem

    onHoveredChanged: {
        if (hovered) {
            pointerEntered = true
        } else if (pointerEntered && popup.visible) {
            popup.visible = false
        }
    }
}
