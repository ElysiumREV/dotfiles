import QtQuick
import QtQuick.Controls
import ".." as Config

Slider {
    id: root

    property int trackThickness: 6
    property int thumbSize: 14

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: root.trackThickness
        radius: height / 2
        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                       Config.Theme.colTextSec.b, 0.2)

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: Config.Theme.colHighlight
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.thumbSize
        height: root.thumbSize
        radius: width / 2
        color: Config.Theme.colFg
    }
}
