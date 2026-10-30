import QtQuick
import ".." as Config

Item {
    id: root

    height: Config.Theme.moduleHeight
    property real contentWidth: 0
    property bool interactive: false
    property bool selected: false
    property bool backgroundVisible: true
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool highlighted: interactive && (hovered || activeFocus || selected)

    // Grupos ocultos deixam de reservar largura no Row e nas relações de âncora.
    width: visible ? contentWidth + 10 : 0

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.topMargin: (root.height - Config.Theme.moduleGroupHeight) / 2
        anchors.bottomMargin: (root.height - Config.Theme.moduleGroupHeight) / 2
        radius: Config.Theme.moduleGroupRadius
        visible: root.backgroundVisible || root.highlighted
        color: root.highlighted ? Config.Theme.colHighlightContainer : Config.Theme.colPanel

        Behavior on color {
            ColorAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveEffects
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.interactive
    }
}
