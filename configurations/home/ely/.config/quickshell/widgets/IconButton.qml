import QtQuick
import QtQuick.Controls
import ".." as Config

Button {
    id: root

    property string iconName: ""
    property bool selected: false
    property bool prominent: false
    property bool filled: false
    property int iconSize: 19
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
                ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                          Config.Theme.colTextSec.b, 0.12)
                : ((root.selected || root.hovered || root.activeFocus)
                ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                          Config.Theme.colHighlight.b,
                          root.selected ? Config.Theme.stateSelectedOpacity : Config.Theme.stateHoverOpacity)
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
