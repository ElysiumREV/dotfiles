import QtQuick
import ".." as Config

Rectangle {
    id: root

    property color surfaceColor: Config.Theme.colSurface
    property color outlineColor: Config.Theme.colBorderSubtle
    property real outlineOpacity: 0.36
    property int cornerRadius: Config.Theme.radiusCard
    property bool outlined: true

    radius: cornerRadius
    color: surfaceColor
    border.width: outlined ? 1 : 0
    border.color: Qt.rgba(outlineColor.r, outlineColor.g, outlineColor.b, outlineOpacity)
}
