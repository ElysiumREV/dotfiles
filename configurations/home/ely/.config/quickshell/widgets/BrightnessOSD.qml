import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Config
import "../services" as QsServices

Scope {
    id: root

    readonly property var brightness: QsServices.Brightness
    readonly property int percentage: brightness?.percentage ?? 0

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
                        id: brightnessText
                        text: root.percentage + "%"
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize
                        font.weight: Font.Regular
                        color: Config.Theme.colFg
                    }

                    Text {
                        id: brightnessIcon
                        text: root.icon
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.osdIconSize

                        color: {
                            if (root.percentage >= 75) return Config.Theme.colYellow
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
                                if (root.percentage >= 75) return Config.Theme.colYellow
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
