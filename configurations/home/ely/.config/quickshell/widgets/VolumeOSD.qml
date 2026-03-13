import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            root.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    property bool shouldShowOsd: false
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

    readonly property color gruvboxFg: "#ebdbb2"
    readonly property color gruvboxGray: "#a89984"
    readonly property color gruvboxOrange: "#d65d0e"
    readonly property color gruvboxYellow: "#fabd2f"

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
                color: "#80000000"

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
                        color: root.muted ? root.gruvboxGray : root.gruvboxFg
                        visible: !root.muted
                    }

                    Text {
                        id: volumeIcon
                        text: root.icon
                        font.family: "Material Design Icons"
                        font.pixelSize: 18

                        color: {
                            if (root.muted) return root.gruvboxGray
                            if (root.percentage >= 66) return root.gruvboxYellow
                            return root.gruvboxFg
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
                                if (root.muted) return root.gruvboxGray
                                if (root.percentage >= 66) return root.gruvboxYellow
                                return root.gruvboxFg
                            }

                            Behavior on implicitWidth {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: "transparent"
                            border.color: "#50ffffff"
                            border.width: 1
                        }
                    }
                }
            }
        }
    }
}