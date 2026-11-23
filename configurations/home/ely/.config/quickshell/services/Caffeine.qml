pragma Singleton

import QtQuick
import Quickshell

// "Keep awake": while active, the bar windows hold a Wayland idle inhibitor
// (IdleInhibitor in Bar.qml), so hypridle does not dim, lock or suspend.
// Lasts for the session, like Do Not Disturb.
Singleton {
    property bool active: false

    function toggle(): void {
        active = !active;
    }
}
