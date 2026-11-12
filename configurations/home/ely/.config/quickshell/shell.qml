//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "widgets"
import "modules"
import "services" as Services
import "." as Config

ShellRoot {
    // Start the event-driven watcher with the shell; history itself stays in memory.
    Component.onCompleted: Services.ClipboardHistory.entries

    IpcHandler {
        target: "shell"

        function toggleLauncher(): void { Services.WindowControl.toggleLauncher(); }
        function toggleKeybindCheatsheet(): void {
            keybindCheatsheet.toggle(Hyprland.focusedMonitor);
        }
        function toggleLogout(): void { Services.WindowControl.toggleLogout(); }
        // Called by scripts/browser-chooser.sh, the default handler for web links.
        function openBrowserChooser(url: string): void { Services.WindowControl.openBrowserChooser(url); }
        function toggleBrowserChooser(): void { Services.WindowControl.toggleBrowserChooser(); }
        function screenshotRegion(): void { screenshotSelector.open("region"); }
        function screenshotWindow(): void { screenshotSelector.open("window"); }
        function cancelScreenshot(): void { screenshotSelector.close(); }
        function toggleWallpaper(): void { Services.WindowControl.toggleWallpaper(); }
        function toggleWallhaven(): void { Services.WindowControl.toggleWallhaven(); }
        function toggleClipboardHistory(): void {
            Services.WindowControl.toggleClipboardHistory(Hyprland.focusedMonitor);
        }
        function toggleNotificationCenter(): void {
            Services.Notifications.toggleCenter(Hyprland.focusedMonitor);
        }
        function toggleShortcutHub(): void {
            Services.Notifications.toggleCenter(Hyprland.focusedMonitor, "shortcuts");
        }
        function toggleVolumeMixer(): void {
            Services.Notifications.toggleCenter(Hyprland.focusedMonitor, "volume");
        }
        function toggleScreenRecording(): void {
            Services.ScreenRecorder.toggle();
        }
        function toggleColorMode(): void {
            Services.WallpaperManager.setColorMode(
                Config.Preferences.theme.mode === "light" ? "dark" : "light");
        }
        function toggleDoNotDisturb(): void {
            Services.Notifications.doNotDisturb = !Services.Notifications.doNotDisturb;
        }
        function syncBrightness(): void {
            Services.Brightness.readBrightness();
        }
        function increaseBrightness(): void {
            Services.Brightness.increaseBrightness();
        }
        function decreaseBrightness(): void {
            Services.Brightness.decreaseBrightness();
        }
        function increaseVolume(): void {
            Services.Volume.increaseVolume();
        }
        function decreaseVolume(): void {
            Services.Volume.decreaseVolume();
        }
        function toggleMute(): void {
            Services.Volume.toggleMute();
        }
    }

    Bar {}
    KeybindCheatsheet { id: keybindCheatsheet }
    ScreenshotSelector { id: screenshotSelector }
    NotificationPopups {}
    VolumeOSD {}
    BrightnessOSD {}
    LazyLoader {
        activeAsync: Services.WindowControl.logoutVisible

        WLogout {
            backgroundColor: Config.Theme.colWlogoutBg
            buttonColor: Config.Theme.colWlogoutButton
            buttonHoverColor: Config.Theme.colWlogoutButtonHover
            textColor: Config.Theme.colWlogoutText
            borderColor: Config.Theme.colBorder

            LogoutButton {
                command: "hyprlock"
                keybind: Qt.Key_L
                text: "Lock"
                icon: "lock"
            }

            LogoutButton {
                command: "hyprshutdown --post-cmd 'hyprctl dispatch hl.dsp.exit()'"
                keybind: Qt.Key_E
                text: "Logout"
                icon: "logout"
            }

            LogoutButton {
                command: "hyprshutdown -t 'Sleeping...' --post-cmd 'systemctl suspend'"
                keybind: Qt.Key_U
                text: "Suspend"
                icon: "suspend"
            }

            LogoutButton {
                command: "hyprshutdown -t 'Hibernating...' --post-cmd 'systemctl hibernate'"
                keybind: Qt.Key_H
                text: "Hibernate"
                icon: "hibernate"
            }

            LogoutButton {
                command: "hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"
                keybind: Qt.Key_S
                text: "Shutdown"
                icon: "shutdown"
            }

            LogoutButton {
                command: "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"
                keybind: Qt.Key_R
                text: "Reboot"
                icon: "reboot"
            }
        }
    }
}
