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
            Item {
                id: workspaceItem

                property int workspaceId: index + 1
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

                implicitWidth: workspaceText.implicitWidth
                implicitHeight: Config.Theme.moduleHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: workspaceText.implicitWidth + 10
                    height: 22
                    radius: 6
                    color: Config.Theme.colHighlight
                    opacity: {
                        if (workspaceItem.isActive) return 0.22
                        if (mouseArea.containsMouse) return 0.16
                        return 0
                    }

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Rectangle {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 4
                    }
                    width: workspaceText.implicitWidth
                    height: 2
                    radius: 1
                    color: Config.Theme.colHighlight
                    opacity: mouseArea.containsMouse || workspaceItem.isActive ? 0.9 : 0

                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Text {
                    id: workspaceText

                    anchors.centerIn: parent
                    text: toRoman(workspaceItem.workspaceId)
                    color: {
                        if (workspaceItem.isActive) return Config.Theme.colText
                        if (mouseArea.containsMouse) return Config.Theme.colFg
                        return workspaceItem.ws ? Config.Theme.colTextSec : Config.Theme.colDisabled
                    }
                    font {
                        family: Config.Theme.fontFamily
                        pixelSize: Config.Theme.fontSize
                        bold: true
                    }
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: workspaceItem.ws?.activate()
                }
            }
        }
    }
}
