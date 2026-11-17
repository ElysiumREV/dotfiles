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
    property bool clipboardVisible: false
    property var clipboardMonitor: null
    property bool browserChooserVisible: false
    property var browserChooserMonitor: null
    property string browserChooserUrl: ""
    property bool googleDriveVisible: false
    property var googleDriveMonitor: null

    function closeOverlays(): void {
        launcherVisible = false;
        launcherMonitor = null;
        logoutVisible = false;
        wallpaperVisible = false;
        wallpaperMonitor = null;
        wallhavenVisible = false;
        wallhavenMonitor = null;
        clipboardVisible = false;
        clipboardMonitor = null;
        browserChooserVisible = false;
        browserChooserMonitor = null;
        googleDriveVisible = false;
        googleDriveMonitor = null;
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

    // url = "" opens a new browser window instead of a link.
    function openBrowserChooser(url): void {
        closeOverlays();
        browserChooserUrl = url ?? "";
        browserChooserMonitor = Hyprland.focusedMonitor;
        browserChooserVisible = true;
    }

    function toggleBrowserChooser(): void {
        if (browserChooserVisible)
            closeOverlays();
        else
            openBrowserChooser("");
    }

    // Google Drive account chooser (hypr/scripts/gdrive.sh).
    function toggleGoogleDrive(): void {
        if (googleDriveVisible) {
            closeOverlays();
        } else {
            closeOverlays();
            googleDriveMonitor = Hyprland.focusedMonitor;
            googleDriveVisible = true;
        }
    }

    function toggleClipboardHistory(monitor): void {
        if (clipboardVisible && clipboardMonitor === monitor) {
            closeOverlays();
            return;
        }
        closeOverlays();
        clipboardMonitor = monitor;
        clipboardVisible = true;
    }
}
