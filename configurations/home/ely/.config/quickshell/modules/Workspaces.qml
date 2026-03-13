import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    // Theme
    property color colBg: "#1a1b26"
    property color colFg: "#c0caf5"
    property color colMuted: "#414868"
    property color colCyan: "#7dcfff"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
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
