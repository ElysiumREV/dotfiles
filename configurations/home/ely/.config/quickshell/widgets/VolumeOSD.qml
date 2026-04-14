import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
    id: root
    property color colBg: "#13151A"
            property color colFg: "#d4c5b0"
            property color colText: "#F0F1F5"
            property color colTextSec: "#B8BCCA"
            property color colMuted: "#7C8291"
            property color colDisabled: "#505563"
            property color colHighlight: "#A08EC4"
            property color colBlue: "#7EA3CC"
            property color colYellow: "#e6c97a"
            property color colRed: "#C47A7A"
            property color colOrange: "#C4956A"
            property color colGreen: "#7EBD9B"
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 14

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            if (!root.startupComplete) return;
            root.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    property bool shouldShowOsd: false
    property bool startupComplete: false

    Timer {
        id: startupTimer
        interval: 2000
        running: true
        onTriggered: root.startupComplete = true
    }

    readonly property var volume: Pipewire.defaultAudioSink?.audio
    readonly property int percentage: volume ? Math.round(volume.volume * 100) : 0
    readonly property bool muted: volume?.mute ?? false
    readonly property string icon: {
        if (!volume) return "󰕾"
        if (muted) return "󰝟"
        if (percentage <= 33) return "󰕿"
        if (percentage <= 66) return "󰖀"
        return "󰕾"
    }

    readonly property color monoFg: "#d4c5b0"
    readonly property color monoMuted: "#2a1a1a"
    readonly property color monoYellow: "#e6c97a"

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 5
            exclusiveZone: 0

            implicitHeight: 50
            implicitWidth: 200
            color: "transparent"

            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#cc181616"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 15
                        rightMargin: 20
                    }
                    spacing: 10

                    Text {
                        id: volumeText
                        text: root.percentage + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.weight: Font.Regular
                        color: root.muted ? root.monoMuted : root.monoFg
                        visible: !root.muted
                    }

                    Text {
                        id: volumeIcon
                        text: root.icon
                        font.family: root.fontFamily
                        font.pixelSize: 18

                        color: {
                            if (root.muted) return root.monoMuted
                            if (root.percentage >= 66) return root.monoYellow
                            return root.monoFg
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }

                            implicitWidth: parent.width * (root.percentage / 100)
                            height: parent.height
                            radius: 20
                            color: {
                                if (root.muted) return root.monoMuted
                                if (root.percentage >= 66) return root.monoYellow
                                return root.monoFg
                            }

                            Behavior on implicitWidth {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: "transparent"
                            border.color: "#50c5c9c5"
                            border.width: 1
                        }
                    }
                }
            }
        }
    }
}