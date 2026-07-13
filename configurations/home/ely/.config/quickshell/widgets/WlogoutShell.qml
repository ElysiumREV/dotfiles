import QtQuick
import Quickshell

ShellRoot {
	WLogout {
		// Lock - trava a sessão
		LogoutButton {
			command: "hyprlock"
			keybind: Qt.Key_L
			text: "Lock"
			icon: "lock"
		}

		// Logout - sai do Hyprland
		LogoutButton {
			command: "hyprshutdown --post-cmd 'hyprctl dispatch hl.dsp.exit()'"
			keybind: Qt.Key_E
			text: "Logout"
			icon: "logout"
		}

		// Suspend - suspende o sistema
		LogoutButton {
			command: "hyprshutdown -t 'Sleeping...' --post-cmd 'systemctl suspend'"
			keybind: Qt.Key_U
			text: "Suspend"
			icon: "suspend"
		}

		// Hibernate - hiberna o sistema
		LogoutButton {
			command: "hyprshutdown -t 'Hibernating...' --post-cmd 'systemctl hibernate'"
			keybind: Qt.Key_H
			text: "Hibernate"
			icon: "hibernate"
		}

		// Shutdown - desliga o sistema
		LogoutButton {
			command: "hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"
			keybind: Qt.Key_S
			text: "Shutdown"
			icon: "shutdown"
		}

		// Reboot - reinicia o sistema
		LogoutButton {
			command: "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"
			keybind: Qt.Key_R
			text: "Reboot"
			icon: "reboot"
		}
	}
}
