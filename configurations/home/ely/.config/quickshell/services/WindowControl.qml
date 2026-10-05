pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    property bool launcherVisible: false
    property var launcherMonitor: null
    property bool logoutVisible: false
    property bool wallpaperVisible: false
    property var wallpaperMonitor: null

    function openLauncher(monitor): void {
        launcherMonitor = monitor;
        launcherVisible = true;
    }

    function toggleLauncher(): void {
        if (launcherVisible) {
            launcherVisible = false;
        } else {
            openLauncher(Hyprland.focusedMonitor);
        }
    }

    function toggleLogout(): void {
        logoutVisible = !logoutVisible;
    }

    function openWallpaper(monitor): void {
        wallpaperMonitor = monitor;
        wallpaperVisible = true;
    }

    function toggleWallpaper(): void {
        if (wallpaperVisible) {
            wallpaperVisible = false;
            wallpaperMonitor = null;
        } else {
            openWallpaper(Hyprland.focusedMonitor);
        }
    }
}
