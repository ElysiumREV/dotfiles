import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Config
import "../widgets" as Widgets
import "../services" as QsServices

Item {
    id: root

    required property var targetScreen
    readonly property bool isHovered: mouseArea.containsMouse

    implicitWidth: mediaRow.implicitWidth
    implicitHeight: Config.Theme.moduleHeight

    readonly property var media: QsServices.Media
    property real screenWidth: 0

    // Keeps stable space in the bar (no flicker/disappearing).
    opacity: media.connected ? 1 : 0.65

    Behavior on opacity {
        NumberAnimation {
            duration: Config.Theme.motionFast
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Theme.curveEffects
        }
    }

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: media.connected
        ? media.displayName + ": " + media.displayArtist + " — " + media.displayTitle
            + (media.playing ? ", playing" : ", paused")
        : "No media playing"

    function togglePopup() {
        if (mediaPopupLoader.activeAsync) {
            mediaPopupLoader.item.visible = false
            mediaPopupLoader.activeAsync = false
        } else {
            mediaPopupLoader.activeAsync = true
        }
    }

    // Enter/Space open the player card; Left/Right change track.
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.togglePopup()
        } else if (event.key === Qt.Key_Left) {
            media.previous()
        } else if (event.key === Qt.Key_Right) {
            media.next()
        } else {
            return
        }
        event.accepted = true
    }

    Rectangle {
        anchors.centerIn: parent
        width: mediaRow.implicitWidth + 8
        height: Config.Theme.moduleHeight - 4
        radius: height / 2
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Config.Theme.colHighlight
    }

    function popupPosition(width) {
        const point = root.QsWindow.mapFromItem(
            root,
            (root.implicitWidth - width) / 2,
            root.implicitHeight
        )
        return {
            x: Math.max(0, Math.min(point.x, Math.max(0, root.screenWidth - width)))
        }
    }

    RowLayout {
        id: mediaRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleInnerSpacing

        // Play/pause icon
        Text {
            id: playIcon
            Layout.alignment: Qt.AlignVCenter
            text: media.playing ? "pause" : "music_note"
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.Theme.iconSizeSm
            color: media.playing ? Config.Theme.colGreen : Config.Theme.colMuted
            verticalAlignment: Text.AlignVCenter
        }

        // Info on one line: "Artist — Track"
        Text {
            id: trackText
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: Config.Theme.mediaMaxWidth

            text: {
                const a = (media.artist || "").trim()
                const t = (media.title || "").trim()
                if (a && t) return a + " — " + t
                return a || t || media.displayName
            }

            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            font.weight: Font.DemiBold
            color: media.connected ? Config.Theme.colFg : Config.Theme.colMuted
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        // Volume indicator (when non-zero)
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: media.volume > 0 ? " " + media.volume + "%" : ""
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            color: Config.Theme.colMuted
            visible: media.connected && media.volumeSupported
            verticalAlignment: Text.AlignVCenter
        }

        // Music icon
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "music_note"
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.Theme.iconSizeSm
            color: {
                if (isHovered) return Config.Theme.colBlue
                if (media.playing) return Config.Theme.colGreen
                return Config.Theme.colFg
            }
            verticalAlignment: Text.AlignVCenter
        }
    }

    Widgets.WheelAccumulator { id: wheelSteps }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.togglePopup()

        // Scroll for volume (Shift + scroll) or navigation (normal)
        WheelHandler {
            onWheel: event => {
                const steps = wheelSteps.feed(event.angleDelta.y)
                if (steps === 0)
                    return
                if (event.modifiers & Qt.ShiftModifier) {
                    // Shift + scroll = volume, 5% per step
                    media.setVolume(media.volume + steps * 5)
                } else if (steps > 0) {
                    // Scroll = next/previous, one track per gesture step
                    media.next()
                } else {
                    media.previous()
                }
            }
        }
    }

    LazyLoader {
        id: mediaPopupLoader

        MediaPopup {
            targetScreen: root.targetScreen
            media: root.media
            positionProvider: root.popupPosition
        }

        onActiveChanged: if (active && item) item.openPopup()
    }

    Connections {
        target: mediaPopupLoader.item
        function onVisibleChanged() {
            if (target && !target.visible)
                mediaPopupLoader.activeAsync = false
        }
    }
}
