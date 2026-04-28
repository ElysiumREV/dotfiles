import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as QsServices

Scope {
    id: root

    readonly property var brightness: QsServices.Brightness
    readonly property int percentage: brightness?.percentage ?? 0

    property color monoFg: "#d4c5b0"
    property color monoYellow: "#e6c97a"
    property string fontFamily: "JetBrainsMono Nerd Font"

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
                color: "#cc181616"

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
                        font.family: root.fontFamily
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
                            border.color: "#50c5c9c5"
                            border.width: 1
                        }
                    }
                }
            }
        }
    }
}
