import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Config
import "../widgets" as Widgets

PanelWindow {
    id: root

    required property var targetScreen
    required property var sourceToplevel
    required property real popupX

    screen: targetScreen
    visible: sourceToplevel !== null
    color: "transparent"
    implicitWidth: 390
    implicitHeight: 260
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        left: popupX
    }

    onVisibleChanged: {
        if (visible) {
            unavailable = false;
            unavailableTimer.restart();
        } else {
            unavailableTimer.stop();
        }
    }

    property bool unavailable: false

    Timer {
        id: unavailableTimer
        interval: 1800
        repeat: false
        onTriggered: if (!preview.hasContent) root.unavailable = true
    }

    Widgets.SurfaceCard {
        anchors.fill: parent
        anchors.margins: 0
        clip: true
        radius: Config.Theme.radiusCard
        surfaceColor: Config.Theme.colBg
        outlineColor: Config.Theme.colBorderSubtle

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: Config.Theme.spaceSm
            Text {
                Layout.fillWidth: true
                text: root.sourceToplevel?.title || "Workspace window"
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                font.bold: true
                elide: Text.ElideRight
            }

            Item {
                id: previewFrame
                Layout.fillWidth: true
                Layout.fillHeight: true

                ScreencopyView {
                    id: preview

                    readonly property real scaleFactor: hasContent
                        && sourceSize.width > 0 && sourceSize.height > 0
                        ? Math.min(1, Math.min(
                            previewFrame.width / sourceSize.width,
                            previewFrame.height / sourceSize.height
                        )) : 1

                    anchors.centerIn: parent
                    width: hasContent ? sourceSize.width * scaleFactor : parent.width
                    height: hasContent ? sourceSize.height * scaleFactor : parent.height
                    captureSource: root.sourceToplevel
                    constraintSize: Qt.size(368, 218)
                    live: true

                    onHasContentChanged: {
                        if (hasContent) unavailableTimer.stop();
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Config.Theme.radiusControl
                    color: Config.Theme.colSurface
                    visible: !preview.hasContent

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 24
                        text: root.unavailable
                            ? "Preview unavailable on this compositor"
                            : "Capturing preview…"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
