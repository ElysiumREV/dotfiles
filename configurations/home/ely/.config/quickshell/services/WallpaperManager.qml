pragma Singleton

import Quickshell
import Quickshell.Io
import ".." as Config

Singleton {
    id: root

    readonly property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string wallpaperDirectory: Config.Preferences.wallpaper.directory.trim()
        || defaultDirectory
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

        pendingPath = wallpaperDirectory + "/wallhaven-" + safeId + "." + safeExtension;
        failureMessage = "Falha ao baixar o wallpaper do Wallhaven.";
        busy = true;
        status = "Baixando wallpaper…";
        downloadProcess.exec([
                                 "sh", "-c",
                                 "mkdir -p \"$2\" && exec curl -fL --retry 2 --connect-timeout 15 --max-time 180 --output \"$3\" \"$1\"",
                                 "wallhaven-download", wallpaper.path, wallpaperDirectory, pendingPath
                             ]);
    }

    function switchWallpaper() {
        status = "Aplicando wallpaper…";
        wallpaperProcess.exec([
                                  "sh", "-c",
                                  `if command -v swww >/dev/null 2>&1; then
exec swww img "$1" --transition-type random --transition-fps 60
else
exec awww img "$1" --transition-type random --transition-fps 60
fi`,
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
            applyColorsProcess.exec([
                                    "bash",
                                    Quickshell.env("HOME") + "/.config/quickshell/scripts/apply_colors.sh",
                                    root.pendingPath
                                ]);
        }
    }

    Process {
        id: applyColorsProcess
        onExited: (exitCode, exitStatus) => {
            root.finish(true, exitCode === 0
                        ? "Wallpaper e paleta atualizados."
                        : "Wallpaper trocado, mas a geração de cores pelo Matugen falhou.");
        }
    }
}
