pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias bar: settingsAdapter.bar
    property alias launcher: settingsAdapter.launcher
    property alias wallpaper: settingsAdapter.wallpaper
    property alias notifications: settingsAdapter.notifications
    property alias theme: settingsAdapter.theme
    property alias recorder: settingsAdapter.recorder
    property alias dns: settingsAdapter.dns
    property alias display: settingsAdapter.display
    // True once settings.json was read (values are the defaults before that).
    property bool loaded: false

    FileView {
        id: settingsFile
        path: Quickshell.shellPath("settings.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.loaded = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
            root.loaded = true
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

            property JsonObject recorder: JsonObject {
                // Both go through the portal (respects no_screen_share rules).
                // "screen" remembers the monitor picked the first time;
                // "window" asks the picker on every recording.
                property string captureMode: "screen"
                // "" = no microphone, "default_input" or a PipeWire source name.
                property string microphone: ""
                property bool systemAudio: true
                // Empty = ~/Videos
                property string directory: ""
            }

            property JsonObject dns: JsonObject {
                // DNS for every network: "auto" (the network's own), a provider id
                // from DnsControl.providers, or "custom" with the servers below.
                property string defaultMode: "auto"
                property string defaultIpv4: ""
                property string defaultIpv6: ""
                // Per-network exceptions are kept by DnsControl in the state
                // directory (dns-overrides.json), out of this backed-up file.
            }

            property JsonObject display: JsonObject {
                // hyprsunset: night light and its warmth (K), and gamma (%, also
                // the way to dim a desktop monitor that has no backlight).
                property bool nightLight: false
                property int temperature: 4000
                property int gamma: 100
            }

            property JsonObject theme: JsonObject {
                // "dark" (default) or "light"; applied by scripts/apply_colors.sh
                property string mode: "dark"
            }
        }
    }
}
