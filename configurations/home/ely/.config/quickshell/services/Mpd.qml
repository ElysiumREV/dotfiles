import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool connected: false
    property bool playing: false
    property string title: ""
    property string artist: ""
    property string album: ""
    property int volume: 0

    readonly property string displayTitle: title || "Unknown Title"
    readonly property string displayArtist: artist || "Unknown Artist"

    Component.onCompleted: mpdProc.running = true

    // Processo único que busca todas as informações de uma vez.
    // Usar StdioCollector faz a atualização ser "atômica" e evita flicker no módulo.
    Process {
        id: mpdProc
        command: ["sh", "-c", `\
            mpc status >/dev/null 2>&1 || exit 1; \
            (mpc current -f '%title%' 2>/dev/null || echo ""); \
            (mpc current -f '%artist%' 2>/dev/null || echo ""); \
            (mpc current -f '%album%' 2>/dev/null || echo ""); \
            (mpc status 2>/dev/null | sed -n 's/.*volume: \\([0-9][0-9]*\\)%.*/\\1/p' | head -n1 || echo "0"); \
            (mpc status 2>/dev/null | sed -n 's/.*\\[\\(playing\\|paused\\|stopped\\)\\].*/[\\1]/p' | head -n1 || echo "[stopped]"); \
            echo "__QS_MPD_OK__" \
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = (text ?? "").split("\n")
                while (lines.length > 0 && (lines[lines.length - 1] ?? "").trim() === "")
                    lines.pop()

                if ((lines[lines.length - 1] ?? "").trim() !== "__QS_MPD_OK__") {
                    if (root.connected) root.connected = false
                    return
                }
                while (lines.length < 6)
                    lines.push("")

                const currentTitle = (lines[0] ?? "").trim()
                const currentArtist = (lines[1] ?? "").trim()
                const currentAlbum = (lines[2] ?? "").trim()
                const currentVolumeStr = (lines[3] ?? "").trim()
                const currentStatusLine = (lines[4] ?? "").trim()

                const parsedVolume = parseInt(currentVolumeStr)
                const newVolume = !isNaN(parsedVolume) ? parsedVolume : 0
                const newPlaying = currentStatusLine.includes("[playing]")

                if (!root.connected) root.connected = true
                if (root.title !== currentTitle) root.title = currentTitle
                if (root.artist !== currentArtist) root.artist = currentArtist
                if (root.album !== currentAlbum) root.album = currentAlbum
                if (root.volume !== newVolume) root.volume = newVolume
                if (root.playing !== newPlaying) root.playing = newPlaying
            }
        }

        // Sem onExited: a confirmação de sucesso/falha vem do marcador __QS_MPD_OK__.
    }

    // Timer com polling a cada 2 segundos
    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!mpdProc.running) {
                mpdProc.running = true
            }
        }
    }

    function togglePlayPause() {
        mpcCommand("toggle")
    }

    function next() {
        mpcCommand("next")
    }

    function previous() {
        mpcCommand("prev")
    }

    function setVolume(val) {
        mpcCommand("volume", val)
        root.volume = Math.max(0, Math.min(100, val))
    }

    // Helper para executar comandos mpc
    function mpcCommand(cmd, arg) {
        var args = arg !== undefined ? ["mpc", cmd, arg.toString()] : ["mpc", cmd]
        var proc = Qt.createQmlObject(`import Quickshell; Process { command: ${JSON.stringify(args)} }`, root)
        proc.running = true
    }
}
