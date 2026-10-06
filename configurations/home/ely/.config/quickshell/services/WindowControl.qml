pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    property bool launcherVisible: false
    property var launcherMonitor: null
    property bool logoutVisible: false
    property bool wallpaperVisible: false
    property var wallpaperMonitor: null
    property bool wallhavenVisible: false
    property var wallhavenMonitor: null

    function closeOverlays(): void {
        launcherVisible = false;
        launcherMonitor = null;
        logoutVisible = false;
        wallpaperVisible = false;
        wallpaperMonitor = null;
        wallhavenVisible = false;
        wallhavenMonitor = null;
    }

    function openLauncher(monitor): void {
        closeOverlays();
        launcherMonitor = monitor;
        launcherVisible = true;
    }

    function toggleLauncher(): void {
        if (launcherVisible) {
            closeOverlays();
        } else {
            openLauncher(Hyprland.focusedMonitor);
        }
    }

    function toggleLogout(): void {
        if (logoutVisible) {
            closeOverlays();
        } else {
            closeOverlays();
            logoutVisible = true;
        }
    }

    function openWallpaper(monitor): void {
        closeOverlays();
        wallpaperMonitor = monitor;
        wallpaperVisible = true;
    }

    function toggleWallpaper(): void {
        if (wallpaperVisible) {
            closeOverlays();
        } else {
            openWallpaper(Hyprland.focusedMonitor);
        }
    }

    function openWallhaven(monitor): void {
        closeOverlays();
        wallhavenMonitor = monitor;
        wallhavenVisible = true;
    }

    function toggleWallhaven(): void {
        if (wallhavenVisible) {
            closeOverlays();
        } else {
            openWallhaven(Hyprland.focusedMonitor);
        }
    }
}
