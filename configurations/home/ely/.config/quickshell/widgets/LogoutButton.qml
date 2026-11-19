import QtQuick
import Quickshell.Io

QtObject {
    id: button

    required property string command
    required property string text
    // Material Symbols icon name.
    required property string icon
    // Qt key that triggers the action directly (also shown on the tile).
    property var keybind: null
    // Ends the session or the machine state; drawn with the error colors.
    property bool danger: false

    readonly property string keyLabel: keybind >= Qt.Key_A && keybind <= Qt.Key_Z
        ? String.fromCharCode(keybind) : ""

    readonly property Process process: Process {
        command: ["sh", "-c", button.command]
    }

    function exec() {
        process.startDetached();
    }
}
