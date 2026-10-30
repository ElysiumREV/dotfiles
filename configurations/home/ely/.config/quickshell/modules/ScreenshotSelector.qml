import Quickshell
import Quickshell.Io

Scope {
    id: root

    function open(selectionMode) {
        if (captureProcess.running)
            return;

        // hyprshot --freeze uses hyprpicker to freeze the compositor output
        // before slurp opens its selector. This also works around games that
        // keep the pointer captured while a custom layer-shell overlay is open.
        const mode = selectionMode === "window" ? "window" : "region";
        captureProcess.command = [
            "hyprshot",
            "--freeze",
            "--mode", mode,
            "--output-folder", Quickshell.env("HOME") + "/Pictures/Screenshots"
        ];
        captureProcess.running = true;
    }

    function close() {
        if (captureProcess.running)
            captureProcess.running = false;
    }

    Process {
        id: captureProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("[ScreenshotSelector] hyprshot exited with code", exitCode);
        }
    }
}
