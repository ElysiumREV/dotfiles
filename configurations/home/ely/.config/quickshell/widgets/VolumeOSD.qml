import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import ".." as Config

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
    target: root.volume || null

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

            implicitHeight: Config.Theme.osdHeight
            implicitWidth: Config.Theme.osdWidth
            color: "transparent"

            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Config.Theme.colOsdBg

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Config.Theme.osdLeftMargin
                        rightMargin: Config.Theme.osdRightMargin
                    }
                    spacing: Config.Theme.osdSpacing

                    Text {
                        id: volumeText
                        text: root.percentage + "%"
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize
                        font.weight: Font.Regular
                        color: root.muted ? Config.Theme.colOsdMuted : Config.Theme.colFg
                        visible: !root.muted
                    }

                    Text {
                        id: volumeIcon
                        text: root.icon
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.osdIconSize

                        color: {
                            if (root.muted) return Config.Theme.colOsdMuted
                            if (root.percentage >= 66) return Config.Theme.colYellow
                            return Config.Theme.colFg
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.Theme.osdBarHeight

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }

                            implicitWidth: parent.width * (root.percentage / 100)
                            height: parent.height
                            radius: Config.Theme.osdBarRadius
                            color: {
                                if (root.muted) return Config.Theme.colOsdMuted
                                if (root.percentage >= 66) return Config.Theme.colYellow
                                return Config.Theme.colFg
                            }

                            Behavior on implicitWidth {
                                NumberAnimation { duration: Config.Theme.osdAnimationDuration }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Config.Theme.osdBarRadius
                            color: "transparent"
                            border.color: Config.Theme.colOsdBorder
                            border.width: Config.Theme.osdBorderWidth
                        }
                    }
                }
            }
        }
    }
}
