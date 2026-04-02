import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property color colBg: "#272822"
    property color colFg: "#f8f8f2"
    property color colMuted: "#75715e"
    property color colCyan: "#66d9ef"
    property color colPurple: "#ae81ff"
    property color colDark: "#49483e"
    property color colYellow: "#e6db74"
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
                color: isActive ? colPurple : (ws ? colDark : colMuted)
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
