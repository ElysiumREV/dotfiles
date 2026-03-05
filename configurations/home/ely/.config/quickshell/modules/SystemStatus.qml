import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
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

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Process {
            id: cpuProc
            property int cpuUsage: 0
            property var lastCpuIdle: 0
            property var lastCpuTotal: 0
            command: ["sh", "-c", "head -1 /proc/stat"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data)
                        return;
                    var p = data.trim().split(/\s+/);
                    var idle = parseInt(p[4]) + parseInt(p[5]);
                    var total = p.slice(1, 8).reduce((a, b) => parseInt(a) + parseInt(b), 0);
                    if (cpuProc.lastCpuTotal > 0) {
                        cpuProc.cpuUsage = Math.round(100 * (1 - (idle - cpuProc.lastCpuIdle) / (total - cpuProc.lastCpuTotal)));
                    }
                    cpuProc.lastCpuTotal = total;
                    cpuProc.lastCpuIdle = idle;
                }
            }
            Component.onCompleted: running = true
        }

        Text {
            text: " " + cpuProc.cpuUsage + "%"
            color: root.colCyan
            font.pixelSize: root.fontSize
        }

        Rectangle {
            implicitWidth: 1
            implicitHeight: 16
            color: root.colMuted
        }

        Process {
            id: memProc
            property int memUsage: 0
            command: ["sh", "-c", "free | grep Mem || echo '0 0 0 0'"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data)
                        return;
                    var parts = data.trim().split(/\s+/);
                    var total = parseInt(parts[1]) || 1;
                    var used = parseInt(parts[2]) || 0;
                    memProc.memUsage = Math.round(100 * used / total);
                }
            }
            Component.onCompleted: running = true
        }

        Text {
            text: " " + memProc.memUsage + "%"
            color: root.colCyan
            font.pixelSize: root.fontSize
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                cpuProc.running = true;
                memProc.running = true;
            }
        }
    }
}
