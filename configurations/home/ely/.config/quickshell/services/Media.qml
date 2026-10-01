pragma Singleton

import Quickshell
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
    readonly property string albumArtist: activePlayer?.trackAlbumArtist ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool volumeSupported: activePlayer?.volumeSupported ?? false
    readonly property int volume: volumeSupported ? Math.round((activePlayer?.volume ?? 0) * 100) : 0
    readonly property string identity: activePlayer?.identity ?? ""
    readonly property string desktopEntry: activePlayer?.desktopEntry ?? ""
    readonly property string dbusName: activePlayer?.dbusName ?? ""
    readonly property bool canToggle: activePlayer?.canTogglePlaying ?? false
    readonly property bool canPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canNext: activePlayer?.canGoNext ?? false

    readonly property string displayTitle: title || "Unknown Title"
    readonly property string displayArtist: artist || "Unknown Artist"
    readonly property string displayName: {
        if (!connected) return "MPRIS"
        if (isSpotify(activePlayer)) return "Spotify"
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

    function raisePlayer() {
        if (activePlayer?.canRaise)
            activePlayer.raise()
    }

    function setVolume(value) {
        if (!activePlayer?.volumeSupported) return

        const clamped = Math.max(0, Math.min(100, value))
        activePlayer.volume = clamped / 100
    }
}
