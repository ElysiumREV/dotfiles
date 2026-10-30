import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Config

Button {
    id: root

    property string iconName: ""
    property bool selected: false

    implicitHeight: 38

    contentItem: RowLayout {
        spacing: Config.Theme.spaceXs

        Text {
            text: root.iconName
            color: root.selected || root.activeFocus || root.hovered
                ? Config.Theme.colHighlight : Config.Theme.colTextSec
            font.family: "Material Symbols Rounded"
            font.pixelSize: 19
        }

        Text {
            Layout.fillWidth: true
            text: root.text
            color: root.selected || root.activeFocus || root.hovered
                ? Config.Theme.colFg : Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            font.bold: root.selected
            verticalAlignment: Text.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: Config.Theme.motionFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Theme.curveEffects
                }
            }
        }
    }

    background: Rectangle {
        radius: Config.Theme.radiusControl
        color: root.selected
            ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                      Config.Theme.colHighlight.b, Config.Theme.stateSelectedOpacity)
            : (root.hovered || root.activeFocus
                ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                          Config.Theme.colHighlight.b, Config.Theme.stateHoverOpacity)
                : "transparent")

        Rectangle {
            visible: root.selected
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.58
            height: 2
            radius: 1
            color: Config.Theme.colHighlight

            Behavior on width {
                NumberAnimation {
                    duration: Config.Theme.motionDefault
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Theme.curveSpatialDefault
                }
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
