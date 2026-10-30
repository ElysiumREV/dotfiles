pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias bar: settingsAdapter.bar
    property alias launcher: settingsAdapter.launcher
    property alias wallpaper: settingsAdapter.wallpaper
    property alias notifications: settingsAdapter.notifications

    FileView {
        id: settingsFile
        path: Quickshell.shellPath("settings.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
        }

        JsonAdapter {
            id: settingsAdapter

            property JsonObject bar: JsonObject {
                property bool showFocusedApp: true
                property bool showDate: true
                property bool showTray: true
                property bool showDeviceIndicators: true
                property bool showSystemStatus: true
                property bool showMedia: true
            }

            property JsonObject launcher: JsonObject {
                property bool prioritizeUsage: true
            }

            property JsonObject wallpaper: JsonObject {
                property string directory: ""
            }

            property JsonObject notifications: JsonObject {
                property int defaultTimeoutSeconds: 3
            }
        }
    }
}
