import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    // Theme
    property color colBg: "#1d2021"
    property color colFg: "#ebdbb2"
    property color colMuted: "#3c3836"
    property color colCyan: "#8ec07c"
    property color colBlue: "#83a598"
    property color colYellow: "#fabd2f"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    implicitHeight: 30
    implicitWidth: rowLayout.implicitWidth

    function toRoman(num) {
        const romanNumerals = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
        return romanNumerals[num];
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: 10
            Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                text: toRoman(index + 1)
                color: isActive ? colCyan : (ws ? colBlue : colMuted)
                font {
                    pixelSize: root.fontSize
                    bold: true
                }
                verticalAlignment: Text.AlignVCenter
                height: parent.height

                MouseArea {
                    anchors.centerIn: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }
    }
}
