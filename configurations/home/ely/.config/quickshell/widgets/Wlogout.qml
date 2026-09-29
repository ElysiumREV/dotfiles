import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/generated/colors.json"
        watchChanges: true
        onFileChanged: reloadTimer.restart()

        JsonAdapter {
            id: colorsAdapter

            readonly property JsonObject md3: JsonObject {
                property string surface_dim: "#141218"
                property string surface_container: "#211f26"
                property string primary_container: "#4f378b"
                property string on_surface: "#e6e0e9"
                property string outline: "#49454f"
            }
        }
    }

    Timer {
        id: reloadTimer
        interval: 150
        repeat: false
        onTriggered: colorsFile.reload()
    }

	WLogout {
        backgroundColor: colorsAdapter.md3.surface_dim
        buttonColor: colorsAdapter.md3.surface_container
        buttonHoverColor: colorsAdapter.md3.primary_container
        textColor: colorsAdapter.md3.on_surface
        borderColor: colorsAdapter.md3.outline

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
