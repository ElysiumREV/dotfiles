import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as QsServices

Scope {
    id: root

    readonly property var brightness: QsServices.Brightness
    readonly property int percentage: brightness?.percentage ?? 0

    readonly property color monoFg: "#f8f8f2"
    readonly property color monoMuted: "#75715e"
    readonly property color monoYellow: "#e6db74"

    property bool shouldShowOsd: false
    property int lastPercentage: percentage
    property bool startupComplete: false

    Timer {
        id: startupTimer
        interval: 2000
        running: true
        onTriggered: root.startupComplete = true
    }

    readonly property string icon: {
        if (percentage >= 75) return "󰃠"
        if (percentage >= 50) return "󰃟"
        if (percentage >= 25) return "󰃞"
        return "󰃝"
    }

    onPercentageChanged: {
        if (!startupComplete) return;
        if (percentage !== lastPercentage) {
            root.shouldShowOsd = true;
            hideTimer.restart();
            lastPercentage = percentage;
        }
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
                        id: brightnessText
                        text: root.percentage + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.weight: Font.Regular
                        color: root.monoFg
                    }

                    Text {
                        id: brightnessIcon
                        text: root.icon
                        font.family: "Material Design Icons"
                        font.pixelSize: 18

                        color: {
                            if (root.percentage >= 75) return root.monoYellow
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
                                if (root.percentage >= 75) return root.monoYellow
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
                            border.color: "#50ffffff"
                            border.width: 1
                        }
                    }
                }
            }
        }
    }
}
