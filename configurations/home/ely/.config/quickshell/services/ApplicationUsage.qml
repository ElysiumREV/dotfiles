pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var entries: ({})
    property int revision: 0

    function load() {
        const raw = usageFile.text().trim();
        if (!raw)
            return;

        try {
            const data = JSON.parse(raw);
            entries = data.apps && typeof data.apps === "object" ? data.apps : {};
            revision++;
        } catch (error) {
            console.warn("[ApplicationUsage] Ignoring invalid usage cache:", error);
            entries = {};
        }
    }

    function countFor(id) {
        return entries[id]?.count ?? 0;
    }

    function lastUsedFor(id) {
        return entries[id]?.lastUsed ?? 0;
    }

    function record(id) {
        if (!id)
            return;

        const next = Object.assign({}, entries);
        const previous = next[id] ?? {};
        next[id] = {
            count: (previous.count ?? 0) + 1,
            lastUsed: Date.now()
        };
        entries = next;
        revision++;
        usageFile.setText(JSON.stringify({ version: 1, apps: entries }, null, 2));
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("application-launcher-usage.json")
        blockLoading: true
    }

    Component.onCompleted: load()
}
