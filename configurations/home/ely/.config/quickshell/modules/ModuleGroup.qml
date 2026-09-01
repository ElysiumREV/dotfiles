import QtQuick
import ".." as Config

Rectangle {
    id: root
    height: Config.Theme.moduleGroupHeight
    radius: Config.Theme.moduleGroupRadius
    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, Config.Theme.moduleGroupOpacity)

    property real contentWidth: 0
    width: contentWidth + 12
}
