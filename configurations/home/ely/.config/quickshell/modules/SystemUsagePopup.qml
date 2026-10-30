import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Config
import "../services" as Services
import "../widgets" as Widgets
import "./PopupGeometry.js" as PopupGeometry

PanelWindow {
    id: root

    required property var targetScreen
    required property var positionProvider
    property real popupX: 0
    property real enterProgress: 0

    color: "transparent"
    visible: false
    focusable: visible
    screen: targetScreen
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: PopupGeometry.widthForScreen(targetScreen, 380, 24)
    implicitHeight: PopupGeometry.heightForScreen(
        targetScreen, 540, Config.Theme.barHeight + 8, 16
    )
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        left: root.popupX
    }

    Widgets.FocusDismissBehavior {
        window: root
        dismissAction: () => root.visible = false
    }

    contentItem {
        focus: root.visible
        Keys.onEscapePressed: root.visible = false
    }

    function openPopup() {
        popupX = positionProvider(implicitWidth).x
        Services.SystemStats.setDetailedViewActive(true)
        visible = true
    }

    onVisibleChanged: {
        if (visible)
            openAnimation.restart()
        else {
            enterProgress = 0
            Services.SystemStats.setDetailedViewActive(false)
        }
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "enterProgress"
        from: 0
        to: 1
        duration: Config.Theme.motionEnter
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveEnter
    }

    Rectangle {
        anchors.fill: parent
        clip: true
        opacity: root.enterProgress
        transform: Translate { y: (1 - root.enterProgress) * -10 }
        color: Config.Theme.colBg
        radius: 12
        border.width: 1
        border.color: Qt.rgba(
            Config.Theme.colTextSec.r,
            Config.Theme.colTextSec.g,
            Config.Theme.colTextSec.b,
            0.25
        )

        Text {
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 14
                rightMargin: 14
            }
            text: "close"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 20
            color: closeMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colTextSec
            z: 10

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.visible = false
            }
        }

        ScrollView {
            id: usageScroll
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 44
            anchors.bottomMargin: 16
            clip: true
            contentWidth: availableWidth
            ScrollBar.vertical: Widgets.ThemeScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                width: usageScroll.availableWidth
                height: implicitHeight
                spacing: 13

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "monitoring"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 23
                    color: Config.Theme.colHighlight
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "System usage"
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize + 1
                        font.bold: true
                    }

                    Text {
                        text: "Updates every 5 seconds"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize - 2
                    }
                }

            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25) }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "developer_board"; font.family: "Material Symbols Rounded"; font.pixelSize: 19; color: Config.Theme.colHighlight }
                    Text { Layout.fillWidth: true; text: "Processor"; color: Config.Theme.colFg; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize; font.bold: true }
                    Text { text: Services.SystemStats.cpuUsage + "%"; color: Config.Theme.colFg; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize; font.bold: true }
                }

                UsageBar {
                    Layout.fillWidth: true
                    value: Services.SystemStats.cpuUsage
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.width < 340 ? 2 : 3
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: Services.SystemStats.cpuCores.slice(0, 12)

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 45
                            radius: 7
                            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.08)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 3
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Core " + (modelData.id + 1); color: Config.Theme.colTextSec; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize - 3 }
                                    Text { text: modelData.usage + "%"; color: Config.Theme.colFg; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize - 3 }
                                }
                                UsageBar {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    value: modelData.usage
                                    implicitHeight: 4
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: Services.SystemStats.cpuCores.length > 12
                    text: "+ " + (Services.SystemStats.cpuCores.length - 12) + " more cores"
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSize - 2
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25) }

            UsageSection {
                Layout.fillWidth: true
                icon: "memory"
                title: "Memory"
                percent: Services.SystemStats.memoryUsage
                details: root.formatMemory(Services.SystemStats.memoryTotalKb - Services.SystemStats.memoryAvailableKb)
                    + " used of " + root.formatMemory(Services.SystemStats.memoryTotalKb)
                footnote: root.formatMemory(Services.SystemStats.memoryAvailableKb) + " available"
            }

            UsageSection {
                Layout.fillWidth: true
                icon: "swap_horiz"
                title: "Swap"
                percent: Services.SystemStats.swapUsage
                details: Services.SystemStats.swapTotalKb > 0
                    ? root.formatMemory(Services.SystemStats.swapTotalKb - Services.SystemStats.swapFreeKb) + " used of " + root.formatMemory(Services.SystemStats.swapTotalKb)
                    : "Swap is not configured"
                footnote: Services.SystemStats.swapTotalKb > 0
                    ? root.formatMemory(Services.SystemStats.swapFreeKb) + " free"
                    : ""
                visible: true
            }
            }
        }
    }

    function formatMemory(kb) {
        return (Math.max(0, kb) / 1024 / 1024).toFixed(1) + " GiB"
    }

    component UsageBar: Rectangle {
        id: usageBar
        required property int value
        implicitWidth: 100
        implicitHeight: 7
        radius: height / 2
        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.16)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, usageBar.value)) / 100
            height: parent.height
            radius: parent.radius
            color: Config.Theme.colHighlight
        }
    }

    component UsageSection: ColumnLayout {
        required property string icon
        required property string title
        required property int percent
        required property string details
        required property string footnote
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text { text: parent.parent.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 19; color: Config.Theme.colHighlight }
            Text { Layout.fillWidth: true; text: parent.parent.title; color: Config.Theme.colFg; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize; font.bold: true }
            Text { text: parent.parent.percent + "%"; color: Config.Theme.colFg; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize; font.bold: true }
        }

        UsageBar { Layout.fillWidth: true; value: parent.percent }

        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: parent.parent.details; color: Config.Theme.colFg; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize - 2 }
            Text { text: parent.parent.footnote; color: Config.Theme.colTextSec; font.family: Config.Theme.fontFamily; font.pixelSize: Config.Theme.fontSize - 2 }
        }
    }
}
