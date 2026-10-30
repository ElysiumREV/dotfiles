pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var pipewire: Pipewire
    readonly property var audioSink: pipewire.defaultAudioSink
    readonly property var audioSource: pipewire.defaultAudioSource

    function audioNodes(isSink, isStream) {
        return pipewire.nodes.values.filter(node =>
            node.audio && node.isSink === isSink && node.isStream === isStream
        );
    }

    readonly property list<var> outputDevices: audioNodes(true, false)
    readonly property list<var> inputDevices: audioNodes(false, false)
    readonly property list<var> outputAppNodes: audioNodes(true, true)

    readonly property bool microphoneMuted: audioSource?.audio?.muted ?? false
    readonly property var captureApplications: {
        const source = audioSource;
        if (!source)
            return [];

        const names = new Set();
        for (const group of microphoneLinks.linkGroups) {
            const target = group.target;
            if (group.source !== source || group.state !== PwLinkState.Active
                    || !target || !target.ready || !target.isStream || !target.isSink)
                continue;

            const properties = target.properties ?? {};
            const name = properties["application.name"] || properties["media.name"]
                || target.description || target.name;
            if (name)
                names.add(String(name));
        }
        return Array.from(names).sort((a, b) => a.localeCompare(b));
    }

    PwObjectTracker {
        objects: [root.audioSink, root.audioSource]
            .concat(microphoneLinks.linkGroups.map(group => group.target))
    }

    PwNodeLinkTracker {
        id: microphoneLinks
        node: root.audioSource
    }

    property var audioIface: null
    property real volume: 0
    property bool muted: false
    property real lastAudibleVolume: 0.5
    property int percentage: 0
    property string icon: "󰕾"
    readonly property bool effectivelyMuted: muted || percentage <= 0

    Component.onCompleted: bindDefaultSink()

    function bindDefaultSink() {
        const nextAudioIface = pipewire.defaultAudioSink?.audio ?? null
        if (audioIface !== nextAudioIface) {
            audioIface = nextAudioIface
            if (audioIface) {
                updateProperties()
            } else {
                volume = 0
                percentage = 0
                muted = false
                icon = "󰕾"
            }
        }
    }

    Connections {
        target: root.pipewire

        function onDefaultAudioSinkChanged() {
            root.bindDefaultSink()
        }
    }

    Connections {
        target: root.audioIface

        function onVolumeChanged() {
            root.updateProperties()
        }

        function onMutedChanged() {
            root.updateProperties()
        }
    }

    function updateProperties() {
        if (audioIface) {
            volume = audioIface.volume ?? 0
            muted = audioIface.muted ?? false
            percentage = Math.round(volume * 100)

            if (!muted && percentage > 0)
                lastAudibleVolume = volume

            if (muted) icon = "󰝟"
            else if (percentage >= 66) icon = "󰕾"
            else if (percentage >= 33) icon = "󰖀"
            else if (percentage > 0) icon = "󰕿"
            else icon = "󰝟"
        }
    }

    function setVolume(value) {
        if (audioIface) {
            const nextVolume = Math.max(0, Math.min(1, value))
            audioIface.volume = nextVolume
            if (nextVolume > 0 && audioIface.muted)
                audioIface.muted = false
            updateProperties()
        }
    }

    function increaseVolume(step = 0.05) {
        setVolume(volume + step)
    }

    function decreaseVolume(step = 0.05) {
        setVolume(volume - step)
    }

    function toggleMute() {
        if (audioIface) {
            if (effectivelyMuted) {
                audioIface.muted = false
                if (percentage <= 0)
                    audioIface.volume = lastAudibleVolume > 0 ? lastAudibleVolume : 0.5
            } else {
                audioIface.muted = true
            }
            updateProperties()
        }
    }

    function toggleMicrophoneMute() {
        if (audioSource?.audio)
            audioSource.audio.muted = !audioSource.audio.muted
    }

    function toggleNodeMute(node) {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function setNodeVolume(node, value) {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, value));
    }
}
