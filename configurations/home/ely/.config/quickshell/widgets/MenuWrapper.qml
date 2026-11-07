import QtQuick
import Config

Item {
    id: root
    
    property bool active: false
    anchors.fill: parent

    Item {
        id: container
        anchors.fill: parent
        
        // Opacidade suave
        opacity: root.active ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.active ? Config.Theme.curveEnter : Config.Theme.curveExit
            }
        }

        // Subtle scale to give depth
        scale: root.active ? 1.0 : 0.98
        Behavior on scale {
            NumberAnimation {
                duration: Config.Theme.motionDefault
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.active ? Config.Theme.curveSpatialDefault : Config.Theme.curveExit
            }
        }

        // "Dropping from the bar" effect: starts above (-20px) and moves down to 0
        y: root.active ? 0 : -20
        Behavior on y {
            NumberAnimation {
                duration: Config.Theme.motionDefault
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.active ? Config.Theme.curveSpatialDefault : Config.Theme.curveExit
            }
        }
        
        default property alias content: data
    }
}
