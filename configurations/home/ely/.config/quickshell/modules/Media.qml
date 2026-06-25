import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." as Config
import "../services" as QsServices

Item {
    id: root

    readonly property bool isHovered: mouseArea.containsMouse

    implicitWidth: mediaRow.implicitWidth
    implicitHeight: Config.Theme.moduleHeight

    QsServices.Media {
        id: media
    }

    // Mantém espaço estável na barra (sem piscar/sumir).
    opacity: media.connected ? 1 : 0.65

    Behavior on opacity { NumberAnimation { duration: 120 } }

    RowLayout {
        id: mediaRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleInnerSpacing

        // Ícone de play/pause
        Text {
            id: playIcon
            Layout.alignment: Qt.AlignVCenter
            text: media.playing ? "" : ""
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSize
            color: media.playing ? Config.Theme.colGreen : Config.Theme.colMuted
            verticalAlignment: Text.AlignVCenter
        }

        // Info em uma linha: "Artista — Música"
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

        // Volume indicator (quando diferente de 0)
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: media.volume > 0 ? " " + media.volume + "%" : ""
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            color: Config.Theme.colMuted
            visible: media.connected && media.volumeSupported
            verticalAlignment: Text.AlignVCenter
        }

        // Ícone musical
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: ""
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSize
            color: {
                if (isHovered) return Config.Theme.colBlue
                if (media.playing) return Config.Theme.colGreen
                return Config.Theme.colFg
            }
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: media.togglePlayPause()

        onDoubleClicked: media.next()

        // Scroll para volume (Shift + scroll) ou navegação (normal)
        WheelHandler {
            onWheel: event => {
                if (event.modifiers & Qt.ShiftModifier) {
                    // Shift + scroll = volume
                    var delta = event.angleDelta.y > 0 ? 5 : -5
                    media.setVolume(media.volume + delta)
                } else {
                    // Scroll normal = next/prev
                    if (event.angleDelta.y > 0) {
                        media.next()
                    } else {
                        media.previous()
                    }
                }
            }
        }
    }
}
