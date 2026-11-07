import QtQuick
import QtQuick.Controls
import ".." as Config

TextField {
    id: root

    property int fieldRadius: Config.Theme.radiusControl
    property int horizontalTextPadding: 12
    property real fillOpacity: 0.10
    property bool flat: false

    color: Config.Theme.colFg
    placeholderTextColor: Config.Theme.colMuted
    font.family: Config.Theme.fontFamily
    font.pixelSize: Config.Theme.fontSize
    leftPadding: horizontalTextPadding

    background: Rectangle {
        visible: !root.flat
        radius: root.fieldRadius
        color: Config.Theme.alpha(Config.Theme.colTextSec, root.fillOpacity)
        border.width: root.activeFocus ? 1 : 0
        border.color: Config.Theme.colHighlight
    }
}
