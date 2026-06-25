import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".." as Config

Item {
    id: root

    implicitHeight: Config.Theme.moduleHeight
    implicitWidth: rowLayout.implicitWidth

    function toRoman(num) {
        const romanNumerals = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
        return romanNumerals[num];
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleInnerSpacing

        Repeater {
            model: 10
            Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                text: toRoman(index + 1)
                color: isActive ? Config.Theme.colText : (ws ? Config.Theme.colTextSec : Config.Theme.colDisabled)
                font {
                    pixelSize: Config.Theme.fontSize
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
