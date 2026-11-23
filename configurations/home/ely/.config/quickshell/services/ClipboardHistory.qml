pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property var entries: []
    property int nextId: 1
    readonly property int maxEntries: 50
    readonly property int maxEntryChars: 32768
    readonly property int maxTotalChars: 524288

    function acceptCapture(line): void {
        let value;
        try {
            value = JSON.parse(line);
        } catch (error) {
            return;
        }
        if (typeof value !== "string" || value.length === 0
                || value.length > maxEntryChars || value.trim().length === 0)
            return;

        const updated = [{ id: nextId++, text: value, timestamp: Date.now() }]
            .concat(entries.filter(entry => entry.text !== value));
        const bounded = [];
        let totalChars = 0;
        for (const entry of updated) {
            if (bounded.length >= maxEntries)
                break;
            if (totalChars + entry.text.length > maxTotalChars)
                continue;
            bounded.push(entry);
            totalChars += entry.text.length;
        }
        entries = bounded;
    }

    function remove(id): void {
        // The newest entry is what the clipboard holds now; removing it (usually
        // something sensitive) clears the clipboard too, so it cannot be pasted.
        if (entries.length > 0 && entries[0].id === id && Quickshell.clipboardText === entries[0].text)
            Quickshell.clipboardText = "";
        entries = entries.filter(entry => entry.id !== id);
    }

    function clear(): void {
        entries = [];
    }

    Process {
        id: watcher
        command: ["wl-paste", "--type", "text", "--watch", "python3",
                  Quickshell.shellDir + "/scripts/clipboard-capture.py"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => ClipboardHistory.acceptCapture(data)
        }

        // wl-paste exits when the Wayland connection goes away (e.g. compositor
        // restart); without a restart the history would silently stop recording.
        onExited: (code, status) => {
            console.warn("[ClipboardHistory] Watcher exited with code", code, "- restarting in",
                restartTimer.interval / 1000, "s");
            restartTimer.restart();
        }
    }

    // Backs off up to 30 s so a missing wl-paste does not spin.
    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: {
            watcher.running = true;
            interval = Math.min(interval * 2, 30000);
        }
    }

    // A watcher that stays up for a minute resets the backoff.
    Timer {
        interval: 60000
        running: watcher.running
        repeat: false
        onTriggered: restartTimer.interval = 2000
    }
}
