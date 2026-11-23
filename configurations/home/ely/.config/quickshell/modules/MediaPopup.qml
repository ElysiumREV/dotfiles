import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
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
        targetScreen, (compactLayout ? 190 : 210) + (media.hasProgress ? 44 : 0),
        Config.Theme.barHeight + 8, 16
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
        media.refreshLiked()
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
        // Space plays/pauses; Left/Right seek 5 s (or change track without seeking).
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space) {
                root.media.togglePlayPause();
            } else if (event.key === Qt.Key_S && root.media.shuffleSupported) {
                root.media.toggleShuffle();
            } else if (event.key === Qt.Key_R && root.media.loopSupported) {
                root.media.cycleLoop();
            } else if (event.key === Qt.Key_L && root.media.likeSupported) {
                root.media.toggleLike();
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                const forward = event.key === Qt.Key_Right;
                if (root.media.canSeek && root.media.hasProgress)
                    root.media.seekTo(root.media.position + (forward ? 5 : -5));
                else if (forward)
                    root.media.next();
                else
                    root.media.previous();
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    Connections {
        target: root.media
        function onTitleChanged() {
            if (root.visible)
                root.media.refreshLiked();
        }
    }

    // MPRIS does not push position updates; poll only while this card is open
    // and the track is playing.
    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible && root.media.playing && root.media.hasProgress
        onTriggered: root.media.refreshPosition()
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

                // Save to / remove from the library (Spotifast only; L on the keyboard).
                ControlButton {
                    Layout.alignment: Qt.AlignTop
                    visible: root.media.likeSupported
                    iconName: "favorite"
                    filledIcon: root.media.likedKnown && root.media.liked
                    active: root.media.likedKnown && root.media.liked
                    small: true
                    available: true
                    label: root.media.liked ? "Remove from your library" : "Save to your library"
                    onClicked: root.media.toggleLike()
                }
            }

            // Progress: drag or click to seek (when the player allows it).
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.media.hasProgress
                spacing: 0

                Widgets.ThemedSlider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, root.media.length)
                    value: root.media.position
                    // Only seek on release, so the 1 s position updates do not fight the drag.
                    live: false
                    enabled: root.media.canSeek
                    trackThickness: 4
                    thumbSize: root.media.canSeek ? 12 : 0
                    Accessible.name: "Track position"
                    onMoved: {
                        root.media.seekTo(value);
                        value = Qt.binding(() => root.media.position);
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: root.media.formatTime(progressSlider.pressed
                            ? progressSlider.valueAt(progressSlider.position) : root.media.position)
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                    }

                    Text {
                        text: root.media.formatTime(root.media.length)
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeCaption
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                ControlButton {
                    visible: root.media.shuffleSupported
                    iconName: "shuffle"
                    active: root.media.shuffle
                    small: true
                    available: true
                    label: root.media.shuffle ? "Turn off shuffle" : "Turn on shuffle"
                    onClicked: root.media.toggleShuffle()
                }

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

                ControlButton {
                    visible: root.media.loopSupported
                    iconName: root.media.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                    active: root.media.loopState !== MprisLoopState.None
                    small: true
                    available: true
                    label: root.media.loopState === MprisLoopState.None ? "Repeat playlist"
                        : root.media.loopState === MprisLoopState.Playlist ? "Repeat this track" : "Turn off repeat"
                    onClicked: root.media.cycleLoop()
                }
            }
        }
    }

    component ControlButton: Rectangle {
        id: control

        required property string iconName
        required property bool available
        property bool emphasized: false
        // Toggle that is on (shuffle, repeat, liked): accent color and a dot below.
        property bool active: false
        property bool small: false
        property bool filledIcon: false
        property string label: iconName
        signal clicked()

        readonly property int size: small ? 30 : 36
        implicitWidth: size
        implicitHeight: size
        width: size
        height: size
        Accessible.role: Accessible.Button
        Accessible.name: label
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
            color: control.emphasized ? Config.Theme.colBg
                : (control.active ? Config.Theme.colHighlight : Config.Theme.colFg)
            font.family: "Material Symbols Rounded"
            font.pixelSize: control.emphasized ? 22 : (control.small ? 18 : 20)
            // Material Symbols variable fill axis: a solid heart when liked.
            font.variableAxes: ({ "FILL": control.filledIcon ? 1 : 0 })
        }

        Rectangle {
            visible: control.active && !control.filledIcon
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            width: 4
            height: 4
            radius: 2
            color: Config.Theme.colHighlight
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
