import QtQuick
import QtQuick.Controls
import ".." as Config

Switch {
    id: root

    property string accessibleLabel: text

    implicitHeight: 42
    Accessible.name: accessibleLabel

    contentItem: Text {
        text: root.text
        color: Config.Theme.colFg
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSize
        verticalAlignment: Text.AlignVCenter
        leftPadding: 0
        rightPadding: root.indicator.width + root.spacing
    }

    indicator: Rectangle {
        x: root.width - width
        y: root.height / 2 - height / 2
        implicitWidth: 42
        implicitHeight: 24
        radius: height / 2
        color: root.checked ? Config.Theme.colHighlight : Config.Theme.colSurface
        border.width: root.checked ? 0 : 1
        border.color: Config.Theme.colBorder

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            y: 3
            width: 18
            height: 18
            radius: height / 2
            color: root.checked ? Config.Theme.colOnHighlight : Config.Theme.colTextSec
            Behavior on x { NumberAnimation { duration: Config.Theme.motionFast } }
        }
    }
}
