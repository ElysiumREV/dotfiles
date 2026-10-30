import QtQuick
import ".." as Config

Item {
    id: root

    property bool requested: false
    property bool keepLoaded: false
    property int exitDuration: Config.Theme.motionEnter + 40
    readonly property bool active: requested || keepLoaded

    visible: false
    width: 0
    height: 0

    onRequestedChanged: {
        if (requested) {
            keepLoaded = true;
            releaseTimer.stop();
        } else if (keepLoaded) {
            releaseTimer.restart();
        }
    }

    Component.onCompleted: if (requested) keepLoaded = true

    Timer {
        id: releaseTimer
        interval: root.exitDuration
        repeat: false
        onTriggered: root.keepLoaded = false
    }
}
