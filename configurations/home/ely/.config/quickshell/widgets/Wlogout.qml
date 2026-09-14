import QtQuick
import Quickshell

ShellRoot {
	WLogout {
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
