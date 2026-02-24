import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    // Theme
    property color colBg: "#1a1b26"
    property color colFg: "#a9b1d6"
    property color colMuted: "#444b6a"
    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    implicitHeight: 30  // Match the bar height
    implicitWidth: rowLayout.implicitWidth

    // Function to convert numbers to Roman numerals (1-9 only)
    function toRoman(num) {
        const romanNumerals = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"];
        return romanNumerals[num];
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent  // Fill the parent Item
        anchors.verticalCenter: parent.verticalCenter  // Center vertically
        spacing: 4

        Repeater {
            model: 9
            Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                text: toRoman(index + 1)  // Convert the number to Roman numeral
                color: isActive ? colCyan : (ws ? colBlue : colMuted)
                font {
                    pixelSize: root.fontSize
                    bold: true
                }
                verticalAlignment: Text.AlignVCenter
                height: parent.height  // Match parent height

                MouseArea {
                    anchors.centerIn: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }
    }
}
