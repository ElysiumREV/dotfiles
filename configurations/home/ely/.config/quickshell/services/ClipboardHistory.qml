pragma Singleton

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

        onExited: (code, status) => {
            if (code !== 0)
                console.warn("Clipboard history watcher exited with code", code);
        }
    }
}
