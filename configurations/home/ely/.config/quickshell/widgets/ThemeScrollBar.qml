import QtQuick
import QtQuick.Controls
import ".." as Config

ScrollBar {
    id: root

    implicitWidth: 6
    implicitHeight: 6
    // Hidden when there is nothing to scroll. An empty list reports size 0 (not
    // 1), which would otherwise draw a full-height bar next to "no results".
    visible: policy === ScrollBar.AlwaysOn || (policy === ScrollBar.AsNeeded && size > 0 && size < 1)

    background: Item {}

    contentItem: Rectangle {
        implicitWidth: 4
        implicitHeight: 4
        radius: width / 2
        color: root.active ? Config.Theme.colHighlight : Config.Theme.colMuted
        opacity: root.active ? 0.9 : 0.5
        Behavior on opacity {
            NumberAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveEffects
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveEffects
            }
        }
    }
}
