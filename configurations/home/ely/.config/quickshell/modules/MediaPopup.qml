import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Config
import "../widgets" as Widgets
import "./PopupGeometry.js" as PopupGeometry

PanelWindow {
    id: root

    required property var targetScreen
    required property var media
    required property var positionProvider
    property real popupX: 0
    property real enterProgress: 0
    readonly property bool compactLayout: (targetScreen?.height ?? 720) < 600

    color: "transparent"
    visible: false
    focusable: visible
    screen: targetScreen
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: PopupGeometry.widthForScreen(targetScreen, 360, 24)
    implicitHeight: PopupGeometry.heightForScreen(
        targetScreen, compactLayout ? 190 : 210, Config.Theme.barHeight + 8, 16
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

    function openPopup() {
        popupX = positionProvider(implicitWidth).x
        enterProgress = 0
        visible = true
        openAnimation.restart()
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

    Widgets.FocusDismissBehavior {
        window: root
        dismissAction: () => root.visible = false
    }

    contentItem {
        focus: root.visible
        Keys.onEscapePressed: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.enterProgress
        transform: Translate { y: (1 - root.enterProgress) * -10 }
        color: Config.Theme.colBg
        radius: Config.Theme.radiusCard
        border.width: 1
        border.color: Config.Theme.alpha(Config.Theme.colTextSec, 0.25)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.compactLayout ? 10 : 14
            spacing: root.compactLayout ? 8 : 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.media.displayName
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "close"
                    color: closeMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colTextSec
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Config.Theme.iconSizeSm

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.compactLayout ? 8 : 12

                Rectangle {
                    Layout.preferredWidth: root.compactLayout ? 60 : 80
                    Layout.preferredHeight: root.compactLayout ? 60 : 80
                    radius: Config.Theme.radiusControl
                    clip: true
                    color: Config.Theme.alpha(Config.Theme.colTextSec, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Config.Theme.colTextSec
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeHero
                        visible: cover.status !== Image.Ready
                    }

                    Image {
                        id: cover
                        anchors.fill: parent
                        source: root.media.artUrl
                        sourceSize.width: 160
                        sourceSize.height: 160
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Config.Theme.spaceXs
                    Text {
                        Layout.fillWidth: true
                        text: root.media.title || "Nothing playing"
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.media.artist || "Unknown artist"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.media.album || "Unknown album"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall - 1
                        elide: Text.ElideRight
                        visible: root.media.album !== ""
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                ControlButton {
                    iconName: "skip_previous"
                    available: root.media.canPrevious
                    onClicked: root.media.previous()
                }

                ControlButton {
                    iconName: root.media.playing ? "pause" : "play_arrow"
                    available: root.media.canToggle
                    emphasized: true
                    onClicked: root.media.togglePlayPause()
                }

                ControlButton {
                    iconName: "skip_next"
                    available: root.media.canNext
                    onClicked: root.media.next()
                }
            }
        }
    }

    component ControlButton: Rectangle {
        id: control

        required property string iconName
        required property bool available
        property bool emphasized: false
        signal clicked()

        implicitWidth: 36
        implicitHeight: 36
        width: 36
        height: 36
        radius: width / 2
        color: emphasized
            ? Config.Theme.colHighlight
            : (controlMouse.containsMouse && available
                ? Config.Theme.alpha(Config.Theme.colFg, 0.12)
                : "transparent")
        opacity: available ? 1 : 0.38

        Text {
            anchors.centerIn: parent
            text: control.iconName
            color: control.emphasized ? Config.Theme.colBg : Config.Theme.colFg
            font.family: "Material Symbols Rounded"
            font.pixelSize: control.emphasized ? 22 : 20
        }

        MouseArea {
            id: controlMouse
            anchors.fill: parent
            enabled: control.available
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: control.clicked()
        }
    }
}
