import QtQuick

HoverHandler {
    id: root

    required property var popup
    property bool pointerEntered: false
    property bool dismissBlocked: false

    parent: popup.contentItem

    onHoveredChanged: {
        if (hovered) {
            pointerEntered = true
        } else if (pointerEntered && popup.visible) {
            Qt.callLater(() => {
                if (pointerEntered && popup.visible && !dismissBlocked && !hovered)
                    popup.visible = false
            })
        }
    }
}
