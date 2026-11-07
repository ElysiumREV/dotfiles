import QtQuick
import Quickshell
import ".." as Config
import "../services" as QsServices

Item {
    id: root

    property bool groupHighlighted: false

    readonly property var volume: QsServices.Volume
    readonly property bool available: !!volume.audioSource?.audio
    readonly property bool muted: volume.microphoneMuted
    readonly property bool isHovered: mouseArea.containsMouse || root.activeFocus

    implicitWidth: 18
    implicitHeight: Config.Theme.moduleHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: !available ? "Microphone unavailable"
        : (muted ? "Unmute microphone" : "Mute microphone")

    Keys.onPressed: event => {
        if (available && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space)) {
            volume.toggleMicrophoneMute();
            event.accepted = true;
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.muted || !root.available ? "mic_off" : "mic"
        color: {
            if (root.groupHighlighted) return Config.Theme.colOnHighlightContainer;
            if (!root.available) return Config.Theme.colDisabled;
            if (root.muted) return Config.Theme.colRed;
            if (root.isHovered) return Config.Theme.colHighlight;
            return Config.Theme.colFg;
        }
        font.family: "Material Symbols Rounded"
        font.pixelSize: Config.Theme.iconSizeSm
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        enabled: root.available
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.volume.toggleMicrophoneMute()
    }
}
