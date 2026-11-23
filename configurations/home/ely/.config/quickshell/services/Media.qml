pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var allowedPlayers: Mpris.players.values.filter(player => isAllowedPlayer(player))
    readonly property var activePlayer: selectPlayer()

    readonly property bool connected: activePlayer !== null
    readonly property bool playing: activePlayer?.isPlaying ?? false
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool volumeSupported: activePlayer?.volumeSupported ?? false
    readonly property int volume: volumeSupported ? Math.round((activePlayer?.volume ?? 0) * 100) : 0
    readonly property string identity: activePlayer?.identity ?? ""
    readonly property string desktopEntry: activePlayer?.desktopEntry ?? ""
    readonly property string dbusName: activePlayer?.dbusName ?? ""
    readonly property bool canToggle: activePlayer?.canTogglePlaying ?? false
    readonly property bool canPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canNext: activePlayer?.canGoNext ?? false
    // Track progress, in seconds. MPRIS does not push position updates while
    // playing: whoever shows it calls refreshPosition() on a timer.
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property bool hasProgress: (activePlayer?.positionSupported ?? false)
        && (activePlayer?.lengthSupported ?? false) && length > 0
    readonly property bool canSeek: activePlayer?.canSeek ?? false

    // Shuffle and repeat go through MPRIS, so they work with any player that supports them.
    readonly property bool shuffleSupported: activePlayer?.shuffleSupported ?? false
    readonly property bool shuffle: activePlayer?.shuffle ?? false
    readonly property bool loopSupported: activePlayer?.loopSupported ?? false
    readonly property int loopState: activePlayer?.loopState ?? MprisLoopState.None

    // "Like" is not part of MPRIS: only Spotifast offers it, through its CLI
    // (`spotifast like` toggles, `spotifast now-playing --raw` reports "saved").
    readonly property bool likeSupported: isSpotifast(activePlayer)
    property bool liked: false
    // Title the `liked` value belongs to, so a stale answer is not shown for another track.
    property string likedTitle: ""
    readonly property bool likedKnown: likeSupported && likedTitle !== "" && likedTitle === title

    readonly property string displayTitle: title || "Unknown Title"
    readonly property string displayArtist: artist || "Unknown Artist"
    readonly property string displayName: {
        if (!connected) return "MPRIS"
        if (isSpotify(activePlayer)) return "Spotify"
        if (isSpotifast(activePlayer)) return "Spotifast"
        if (isYoutubeMusic(activePlayer)) return "YouTube Music"
        return identity || "MPRIS"
    }

    function normalized(value) {
        return (value ?? "").toString().toLowerCase()
    }

    function isSpotify(player) {
        const dbus = normalized(player?.dbusName)
        const entry = normalized(player?.desktopEntry)
        const identity = normalized(player?.identity)

        return dbus === "org.mpris.mediaplayer2.spotify"
            || entry === "spotify"
            || entry === "spotify-launcher"
            || identity === "spotify"
    }

    function isSpotifast(player) {
        const dbus = normalized(player?.dbusName)
        const entry = normalized(player?.desktopEntry)
        const identity = normalized(player?.identity)

        return dbus.indexOf("org.mpris.mediaplayer2.spotifast") === 0
            || entry === "spotifast"
            || entry === "rocks.spotifast.spotifast"
            || identity === "spotifast"
    }

    function isYoutubeMusic(player) {
        const dbus = normalized(player?.dbusName)
        const entry = normalized(player?.desktopEntry)
        const identity = normalized(player?.identity)
        const metadata = player?.metadata ?? ({})
        const url = normalized(metadata["xesam:url"] ?? metadata["url"])

        return dbus.indexOf("org.mpris.mediaplayer2.youtubemusic") === 0
            || dbus.indexOf("org.mpris.mediaplayer2.youtube-music") === 0
            || dbus.indexOf("org.mpris.mediaplayer2.peardesktop") === 0
            || dbus.indexOf("org.mpris.mediaplayer2.pear-desktop") === 0
            || entry === "com.github.th_ch.youtube_music"
            || entry === "youtube music"
            || entry === "youtube-music"
            || entry === "youtube_music"
            || entry === "pear-desktop"
            || entry === "peardesktop"
            || entry === "pear_desktop"
            || identity === "youtube music"
            || identity === "youtubemusic"
            || identity === "pear desktop"
            || url.indexOf("music.youtube.com") !== -1
    }

    function isAllowedPlayer(player) {
        return isSpotify(player) || isSpotifast(player) || isYoutubeMusic(player)
    }

    function selectPlayer() {
        const players = allowedPlayers

        if (!players.length) return null

        const playingPlayer = players.find(player => player.isPlaying)
        if (playingPlayer) return playingPlayer

        const spotify = players.find(player => isSpotify(player))
        if (spotify) return spotify

        return players[0]
    }

    function togglePlayPause() {
        if (activePlayer?.canTogglePlaying)
            activePlayer.togglePlaying()
    }

    function next() {
        if (activePlayer?.canGoNext)
            activePlayer.next()
    }

    function previous() {
        if (activePlayer?.canGoPrevious)
            activePlayer.previous()
    }

    function refreshPosition() {
        activePlayer?.positionChanged()
    }

    function seekTo(seconds) {
        if (!canSeek || !activePlayer)
            return
        activePlayer.position = Math.max(0, Math.min(length, seconds))
    }

    // 3:07, or 1:02:45 for long tracks
    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds))
        const hours = Math.floor(total / 3600)
        const minutes = Math.floor((total % 3600) / 60)
        const secs = String(total % 60).padStart(2, "0")
        return hours > 0 ? hours + ":" + String(minutes).padStart(2, "0") + ":" + secs
                         : minutes + ":" + secs
    }

    function toggleShuffle() {
        if (shuffleSupported)
            activePlayer.shuffle = !activePlayer.shuffle
    }

    // Off -> repeat playlist -> repeat track -> off, like most players.
    function cycleLoop() {
        if (!loopSupported)
            return
        activePlayer.loopState = loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : loopState === MprisLoopState.Playlist ? MprisLoopState.Track
            : MprisLoopState.None
    }

    function refreshLiked() {
        if (likeSupported && !likeQuery.running)
            likeQuery.exec(["spotifast", "now-playing", "--raw"])
    }

    function toggleLike() {
        if (!likeSupported || likeToggle.running)
            return
        // Optimistic: flip now, then confirm with Spotifast once the command ends.
        if (likedKnown)
            liked = !liked
        likeToggle.exec(["spotifast", "like"])
    }

    function setVolume(value) {
        if (!activePlayer?.volumeSupported) return

        const clamped = Math.max(0, Math.min(100, value))
        activePlayer.volume = clamped / 100
    }

    // now-playing --raw: state, title, artists, album, position_ms, duration_ms,
    // volume, shuffle, repeat, art_url, saved, device (tab-separated)
    Process {
        id: likeQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.replace(/\n$/, "").split("\t")
                if (fields.length < 11)
                    return
                root.liked = fields[10] === "yes"
                root.likedTitle = fields[1]
            }
        }
    }

    Process {
        id: likeToggle
        onExited: root.refreshLiked()
    }
}
