import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: root

    property int refreshTick: 0

    readonly property var allowedPlayers: Mpris.players.values.filter(player => isAllowedPlayer(player))
    readonly property var activePlayer: {
        refreshTick
        return selectPlayer()
    }

    readonly property bool connected: activePlayer !== null
    readonly property bool playing: activePlayer?.isPlaying ?? false
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property bool volumeSupported: activePlayer?.volumeSupported ?? false
    readonly property int volume: volumeSupported ? Math.round((activePlayer?.volume ?? 0) * 100) : 0
    readonly property string identity: activePlayer?.identity ?? ""
    readonly property string desktopEntry: activePlayer?.desktopEntry ?? ""
    readonly property string dbusName: activePlayer?.dbusName ?? ""

    readonly property string displayTitle: title || "Unknown Title"
    readonly property string displayArtist: artist || "Unknown Artist"
    readonly property string displayName: {
        if (!connected) return "MPRIS"
        if (isSpotify(activePlayer)) return "Spotify"
        if (isYoutubeMusic(activePlayer)) return "YouTube Music"
        return identity || "MPRIS"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refreshTick++
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

    function isYoutubeMusic(player) {
        const dbus = normalized(player?.dbusName)
        const entry = normalized(player?.desktopEntry)
        const identity = normalized(player?.identity)

        return dbus.indexOf("org.mpris.mediaplayer2.youtubemusic") === 0
            || entry === "com.github.th_ch.youtube_music"
            || entry === "youtube-music"
            || entry === "youtube_music"
            || identity === "youtube music"
    }

    function isAllowedPlayer(player) {
        return isSpotify(player) || isYoutubeMusic(player)
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

    function setVolume(value) {
        if (!activePlayer?.volumeSupported) return

        const clamped = Math.max(0, Math.min(100, value))
        activePlayer.volume = clamped / 100
    }
}
