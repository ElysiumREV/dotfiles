pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property bool busy: false
    property string status: ""
    property string pendingPath: ""
    property string failureMessage: ""

    signal operationFinished(string path, bool success)

    function apply(path) {
        if (busy || !path)
            return;
        pendingPath = path;
        failureMessage = "Falha ao trocar o wallpaper. Confira se o daemon swww/awww está ativo.";
        busy = true;
        switchWallpaper();
    }

    function downloadAndApply(wallpaper) {
        if (busy || !wallpaper?.id || !wallpaper?.path)
            return;

        const extension = wallpaper.path.split(/[?#]/)[0].split(".").pop().toLowerCase();
        const safeExtension = ["jpg", "jpeg", "png", "webp", "avif", "bmp"].includes(extension)
            ? extension : "jpg";
        const safeId = wallpaper.id.toString().replace(/[^a-zA-Z0-9_-]/g, "");
        if (!safeId)
            return;

        pendingPath = defaultDirectory + "/wallhaven-" + safeId + "." + safeExtension;
        failureMessage = "Falha ao baixar o wallpaper do Wallhaven.";
        busy = true;
        status = "Baixando wallpaper…";
        downloadProcess.exec([
            "sh", "-c",
            "mkdir -p \"$2\" && exec curl -fL --retry 2 --connect-timeout 15 --max-time 180 --output \"$3\" \"$1\"",
            "wallhaven-download", wallpaper.path, defaultDirectory, pendingPath
        ]);
    }

    function switchWallpaper() {
        status = "Aplicando wallpaper…";
        wallpaperProcess.exec([
            "sh", "-c",
            "if command -v swww >/dev/null 2>&1; then exec swww img \"$1\"; else exec awww img \"$1\"; fi",
            "wallpaper-switch", pendingPath
        ]);
    }

    function finish(success, message) {
        status = message;
        busy = false;
        operationFinished(pendingPath, success);
    }

    Process {
        id: downloadProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.finish(false, root.failureMessage);
                return;
            }
            root.switchWallpaper();
        }
    }

    Process {
        id: wallpaperProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.finish(false, root.failureMessage);
                return;
            }
            currentLinkProcess.exec([
                "sh", "-c",
                "mkdir -p \"$2\" && ln -sfn \"$1\" \"$2/.current-wallpaper.png\"",
                "wallpaper-link", root.pendingPath, root.defaultDirectory
            ]);
        }
    }

    Process {
        id: currentLinkProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.finish(true, "Wallpaper trocado, mas não consegui atualizar o link do Hyprlock.");
                return;
            }
            matugenProcess.exec([
                "bash", Quickshell.env("HOME") + "/.config/scripts/updateWall.sh"
            ]);
        }
    }

    Process {
        id: matugenProcess
        onExited: (exitCode, exitStatus) => {
            root.finish(true, exitCode === 0
                ? "Wallpaper e paleta atualizados."
                : "Wallpaper trocado, mas a geração de cores pelo Matugen falhou.");
        }
    }
}
