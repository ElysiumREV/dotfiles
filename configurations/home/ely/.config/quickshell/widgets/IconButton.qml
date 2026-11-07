import QtQuick
import QtQuick.Controls
import ".." as Config

Button {
    id: root

    // Qt only activates buttons with Space; make Enter behave like a click too.
    Keys.onReturnPressed: event => { root.clicked(); event.accepted = true; }
    Keys.onEnterPressed: event => { root.clicked(); event.accepted = true; }

    property string iconName: ""
    property bool selected: false
    property bool prominent: false
    property bool filled: false
    property int iconSize: Config.Theme.iconSizeSm
    property int buttonRadius: Config.Theme.radiusControl
    property real iconRotation: 0
    property color idleIconColor: Config.Theme.colTextSec
    property color selectedIconColor: Config.Theme.colHighlight

    implicitWidth: 32
    implicitHeight: 32
    Accessible.name: iconName

    contentItem: Text {
        text: root.iconName
        color: !root.enabled ? Config.Theme.colMuted
            : (root.prominent && (root.hovered || root.activeFocus)
                ? Config.Theme.colOnHighlight
                : (root.selected ? root.selectedIconColor
                    : ((root.hovered || root.activeFocus) ? Config.Theme.colHighlight : root.idleIconColor)))
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.iconSize
        rotation: root.iconRotation
        scale: root.hovered || root.activeFocus ? 1.08 : 1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on rotation {
            NumberAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveSpatialFast
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveEffects
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveSpatialFast
            }
        }
    }

    background: Rectangle {
        radius: root.buttonRadius
        color: root.prominent && (root.hovered || root.activeFocus)
            ? Config.Theme.colHighlight
            : (root.prominent && root.filled
                ? Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
                : ((root.selected || root.hovered || root.activeFocus)
                ? Config.Theme.alpha(Config.Theme.colHighlight, root.selected ? Config.Theme.stateSelectedOpacity : Config.Theme.stateHoverOpacity)
                : "transparent"))
        border.width: root.activeFocus ? 1 : 0
        border.color: Config.Theme.colHighlight

        Behavior on color {
            ColorAnimation {
                duration: Config.Theme.motionFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveEffects
            }
        }
        Behavior on border.width {
            NumberAnimation { duration: Config.Theme.motionFast; easing.type: Easing.OutCubic }
        }
    }
}
