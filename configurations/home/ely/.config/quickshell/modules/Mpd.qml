import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services" as QsServices

Item {
    id: root

    readonly property bool isHovered: mouseArea.containsMouse

    property color colBg: "#13151A"
            property color colFg: "#d4c5b0"
            property color colText: "#F0F1F5"
            property color colTextSec: "#B8BCCA"
            property color colMuted: "#7C8291"
            property color colDisabled: "#505563"
            property color colHighlight: "#A08EC4"
            property color colBlue: "#7EA3CC"
            property color colYellow: "#e6c97a"
            property color colRed: "#C47A7A"
            property color colOrange: "#C4956A"
            property color colGreen: "#7EBD9B"
            property string fontFamily: "JetBrainsMono Nerd Font"
            property int fontSize: 14

    implicitWidth: mpdRow.implicitWidth
    // Deixa a mesma altura dos outros módulos (ex.: SystemStatus) para alinhar na barra.
    implicitHeight: 30

    QsServices.Mpd {
        id: mpd
    }

    // Mantém espaço estável na barra (sem piscar/sumir).
    opacity: mpd.connected ? 1 : 0.65

    Behavior on opacity { NumberAnimation { duration: 120 } }

    RowLayout {
        id: mpdRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Ícone de play/pause
        Text {
            id: playIcon
            Layout.alignment: Qt.AlignVCenter
            text: mpd.playing ? "" : ""
            font.family: root.fontFamily
            font.pixelSize: 14
            color: mpd.playing ? colGreen : colMuted
            verticalAlignment: Text.AlignVCenter
        }

        // Info em uma linha: "Artista — Música"
        Text {
            id: trackText
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 350

            text: {
                const a = (mpd.artist || "").trim()
                const t = (mpd.title || "").trim()
                if (a && t) return a + " — " + t
                return a || t || "MPD"
            }

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: mpd.connected ? colFg : colMuted
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        // Volume indicator (quando diferente de 0)
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: mpd.volume > 0 ? " " + mpd.volume + "%" : ""
            font.family: root.fontFamily
            font.pixelSize: 12
            color: colMuted
            visible: mpd.volume > 0
            verticalAlignment: Text.AlignVCenter
        }

        // Ícone musical
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: ""
            font.family: root.fontFamily
            font.pixelSize: 14
            color: {
                if (isHovered) return colBlue
                if (mpd.playing) return colGreen
                return colFg
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

        onClicked: mpd.togglePlayPause()

        onDoubleClicked: mpd.next()

        // Scroll para volume (Shift + scroll) ou navegação (normal)
        WheelHandler {
            onWheel: event => {
                if (event.modifiers & Qt.ShiftModifier) {
                    // Shift + scroll = volume
                    var delta = event.angleDelta.y > 0 ? 5 : -5
                    mpd.setVolume(mpd.volume + delta)
                } else {
                    // Scroll normal = next/prev
                    if (event.angleDelta.y > 0) {
                        mpd.next()
                    } else {
                        mpd.previous()
                    }
                }
            }
        }
    }
}
