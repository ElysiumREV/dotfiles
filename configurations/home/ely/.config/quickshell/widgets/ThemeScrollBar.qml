import QtQuick
import QtQuick.Controls
import ".." as Config

ScrollBar {
    id: root

    implicitWidth: 6
    implicitHeight: 6

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
