import "../.." as Config
import "../../services" as Services
import "../../widgets" as Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire

ColumnLayout {
    required property var menu
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Config.Theme.spaceSm

    Text {
        Layout.fillWidth: true
        text: "Settings"
        color: Config.Theme.colFg
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSize
        font.bold: true
    }

    Text {
        Layout.fillWidth: true
        text: "Customize the bar, launcher and notifications. Changes are saved automatically."
        color: Config.Theme.colTextSec
        wrapMode: Text.Wrap
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSizeSmall
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "Focused application"
        accessibleLabel: "Show the focused application in the bar"
        checked: Config.Preferences.bar.showFocusedApp
        onToggled: Config.Preferences.bar.showFocusedApp = checked
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "Date in bar"
        accessibleLabel: "Show the date in the bar"
        checked: Config.Preferences.bar.showDate
        onToggled: Config.Preferences.bar.showDate = checked
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "System tray"
        accessibleLabel: "Show system tray icons in the bar"
        checked: Config.Preferences.bar.showTray
        onToggled: Config.Preferences.bar.showTray = checked
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "Device controls"
        accessibleLabel: "Show volume, battery, Wi-Fi, Bluetooth and Do Not Disturb in the bar"
        checked: Config.Preferences.bar.showDeviceIndicators
        onToggled: Config.Preferences.bar.showDeviceIndicators = checked
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "System status"
        accessibleLabel: "Show CPU and memory indicators in the bar"
        checked: Config.Preferences.bar.showSystemStatus
        onToggled: Config.Preferences.bar.showSystemStatus = checked
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "Media"
        accessibleLabel: "Show the media player in the bar"
        checked: Config.Preferences.bar.showMedia
        onToggled: Config.Preferences.bar.showMedia = checked
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "Light mode"
        accessibleLabel: "Use the light color scheme instead of the dark one"
        enabled: !Services.WallpaperManager.busy
        checked: Config.Preferences.theme.mode === "light"
        onToggled: Services.WallpaperManager.setColorMode(checked ? "light" : "dark")
    }

    Widgets.PreferenceSwitch {
        Layout.fillWidth: true
        text: "Prioritize used apps"
        accessibleLabel: "Prioritize recently used applications when launcher results tie"
        checked: Config.Preferences.launcher.prioritizeUsage
        onToggled: Config.Preferences.launcher.prioritizeUsage = checked
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.Theme.spaceSm

        Text {
            Layout.fillWidth: true
            text: "Default notification duration"
            color: Config.Theme.colFg
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSize
        }

        Text {
            text: Config.Preferences.notifications.defaultTimeoutSeconds + " s"
            color: Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
        }
    }

    Widgets.ThemedSlider {
        Layout.fillWidth: true
        from: 1
        to: 10
        stepSize: 1
        value: Config.Preferences.notifications.defaultTimeoutSeconds
        Accessible.name: "Default notification duration in seconds"
        onMoved: Config.Preferences.notifications.defaultTimeoutSeconds = Math.round(value)
    }
}
