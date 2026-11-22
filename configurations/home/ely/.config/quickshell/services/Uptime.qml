pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// System uptime shown by the Arch Menu and the session menu. Read on demand
// (refresh() when a menu opens); no timer runs in the background.
Singleton {
    id: root

    property int seconds: -1
    readonly property string text: seconds < 0 ? "Up …" : format(seconds)

    function refresh(): void {
        uptimeFile.reload();
    }

    function format(value) {
        const days = Math.floor(value / 86400);
        const hours = Math.floor((value % 86400) / 3600);
        const minutes = Math.floor((value % 3600) / 60);
        if (days > 0)
            return "Up " + days + "d " + hours + "h";
        if (hours > 0)
            return "Up " + hours + "h " + minutes + " min";
        return minutes > 0 ? "Up " + minutes + " min" : "Up less than 1 min";
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const value = Number(text().trim().split(/\s+/)[0]);
            if (Number.isFinite(value) && value >= 0)
                root.seconds = Math.floor(value);
        }
    }
}
