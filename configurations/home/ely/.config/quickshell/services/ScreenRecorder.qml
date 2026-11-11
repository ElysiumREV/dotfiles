pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".." as Config

// Screen recording through gpu-screen-recorder (GPU encoding, low overhead).
// Both modes capture through xdg-desktop-portal, so Hyprland's no_screen_share
// rules apply (e.g. notification popups stay out of the video); direct KMS
// capture would bypass the compositor and record them.
//   "screen": the portal session is restored, so the monitor is picked only on
//             the first recording and later ones start right away.
//   "window": the picker opens every time to choose a window or monitor.
Singleton {
    id: root

    // Becomes true once the dependency check has finished; a start requested before is queued.
    property bool checked: false
    property bool available: false
    property bool startPending: false
    // The process is running but capture has not begun (e.g. the portal picker is open).
    property bool starting: false
    // Capture is running; this is what the clock and the bar indicator follow.
    property bool recording: false
    property string lastError: ""
    property bool stopping: false
    property int elapsedSeconds: 0
    property string outputPath: ""
    property string message: ""

    readonly property string directory: Config.Preferences.recorder.directory.trim()
        || Quickshell.env("HOME") + "/Videos"
    readonly property string elapsedText: {
        const minutes = Math.floor(elapsedSeconds / 60);
        const seconds = elapsedSeconds % 60;
        return String(minutes).padStart(2, "0") + ":" + String(seconds).padStart(2, "0");
    }

    signal finished(string path, bool success)

    Component.onCompleted: checkProcess.running = true

    function buildArguments(path) {
        const args = ["gpu-screen-recorder", "-f", "60", "-c", "mp4", "-q", "high"];

        args.push("-w", "portal");
        if (Config.Preferences.recorder.captureMode !== "window")
            args.push("-restore-portal-session", "yes");

        // Several sources joined with "|" are mixed into a single audio track.
        const sources = [];
        if (Config.Preferences.recorder.systemAudio)
            sources.push("default_output");
        if (Config.Preferences.recorder.microphone !== "")
            sources.push(Config.Preferences.recorder.microphone);
        if (sources.length > 0)
            args.push("-a", sources.join("|"));

        args.push("-o", path);
        return args;
    }

    function start() {
        if (starting || recording || recorder.running)
            return;
        if (!checked) {
            startPending = true;
            return;
        }
        if (!available) {
            message = "gpu-screen-recorder is not installed.";
            return;
        }

        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        const path = directory + "/Recording_" + stamp + ".mp4";
        const args = buildArguments(path);

        outputPath = path;
        lastError = "";
        stopping = false;
        elapsedSeconds = 0;
        starting = true;
        message = Config.Preferences.recorder.captureMode === "window"
            ? "Pick a window or monitor in the dialog…" : "Starting… (pick the monitor if asked)";
        // exec keeps the same PID, so the stop signal reaches gpu-screen-recorder itself.
        recorder.exec(["sh", "-c", "mkdir -p \"$1\" && shift && exec \"$@\"", "recorder", directory].concat(args));
    }

    function stop() {
        if (!(starting || recording) || stopping)
            return;
        stopping = true;
        if (recording) {
            // SIGINT makes gpu-screen-recorder finalize the file before exiting.
            recorder.signal(2);
        } else {
            // No frames were captured yet (e.g. the portal picker is still open and
            // blocks the SIGINT handler), so there is nothing to finalize: kill it.
            recorder.signal(9);
        }
    }

    function toggle() {
        if (starting || recording)
            stop();
        else
            start();
    }

    // Called once the encoder reports frames, i.e. after any portal dialog was answered.
    function markCapturing() {
        if (recording || !starting)
            return;
        starting = false;
        recording = true;
        message = "";
        clock.startedAt = Date.now();
        elapsedSeconds = 0;
        clock.restart();
    }

    function notify(title, body, urgency) {
        Quickshell.execDetached(["notify-send", "-a", "Screen recorder", "-u", urgency, "-i", "video-x-generic", title, body]);
    }

    Process {
        id: checkProcess
        command: ["which", "gpu-screen-recorder"]
        onExited: code => {
            root.available = code === 0;
            root.checked = true;
            if (root.startPending) {
                root.startPending = false;
                root.start();
            }
        }
    }

    Process {
        id: recorder

        // gpu-screen-recorder logs "update fps" every second once frames are being encoded.
        stderr: SplitParser {
            onRead: line => {
                if (line.indexOf("update fps") !== -1)
                    root.markCapturing();
                else if (line.indexOf("error") !== -1)
                    root.lastError = line.replace(/^gsr error:\s*/, "");
            }
        }

        onExited: (code, status) => {
            clock.stop();
            const wasRecording = root.recording;
            const wasStopping = root.stopping;
            root.starting = false;
            root.recording = false;
            root.stopping = false;

            if (wasRecording && (code === 0 || wasStopping)) {
                const name = root.outputPath.split("/").pop();
                root.message = "Saved " + name;
                root.notify("Recording saved", root.outputPath, "normal");
                root.finished(root.outputPath, true);
                return;
            }

            if (!wasRecording && (wasStopping || root.lastError === "")) {
                // Cancelled before any frame was captured (picker dismissed or stop pressed).
                root.message = "Recording cancelled.";
                Quickshell.execDetached(["rm", "-f", root.outputPath]);
                // The portal picker outlives a killed recorder; close it as well.
                if (wasStopping)
                    Quickshell.execDetached(["pkill", "-x", "hyprland-share-"]);
                root.finished(root.outputPath, false);
                return;
            }

            root.message = root.lastError !== "" ? root.lastError : "Recording stopped unexpectedly.";
            root.notify("Recording failed", root.message, "critical");
            root.finished(root.outputPath, false);
        }
    }

    Timer {
        id: clock
        property double startedAt: 0
        interval: 1000
        repeat: true
        onTriggered: root.elapsedSeconds = Math.floor((Date.now() - startedAt) / 1000)
    }
}
