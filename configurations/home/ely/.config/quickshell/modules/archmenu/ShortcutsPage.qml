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
        text: "Quick shortcuts"
        color: Config.Theme.colFg
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSize
        font.bold: true
    }

    Text {
        Layout.fillWidth: true
        text: "System and Quickshell actions. Keyboard shortcuts are defined in Hyprland."
        color: Config.Theme.colTextSec
        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontSizeSmall
        wrapMode: Text.WordWrap
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Config.Theme.spaceSm
        columnSpacing: Config.Theme.spaceSm

        Widgets.ActionButton {
            Layout.fillWidth: true
            label: "Lock screen"
            iconName: "lock"
            Accessible.name: label
            onClicked: {
                Services.Notifications.closeCenter();
                Quickshell.execDetached(["hyprlock"]);
            }
        }

        Widgets.ActionButton {
            Layout.fillWidth: true
            label: "Session"
            iconName: "power_settings_new"
            Accessible.name: "Open session actions"
            onClicked: {
                Services.Notifications.closeCenter();
                Services.WindowControl.toggleLogout();
            }
        }

        Widgets.ActionButton {
            Layout.fillWidth: true
            label: "Launcher"
            iconName: "apps"
            Accessible.name: "Open launcher"
            onClicked: {
                Services.Notifications.closeCenter();
                Services.WindowControl.toggleLauncher();
            }
        }

        Widgets.ActionButton {
            Layout.fillWidth: true
            label: "Clipboard"
            iconName: "content_paste"
            Accessible.name: "Open clipboard history"
            onClicked: {
                Services.Notifications.closeCenter();
                Services.WindowControl.toggleClipboardHistory(Hyprland.focusedMonitor);
            }
        }

        Widgets.ActionButton {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            label: "Configure audio"
            iconName: "tune"
            Accessible.name: "Open pavucontrol"
            onClicked: {
                Services.Notifications.closeCenter();
                Quickshell.execDetached(["pavucontrol"]);
            }
        }
    }

    RecorderCard {}

    Item { Layout.fillHeight: true }
}
