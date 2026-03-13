import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color colBg: "#1a1b26"
    property color colFg: "#c0caf5"
    property color colMuted: "#414868"
    property color colCyan: "#7dcfff"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property color colRed: "#f7768e"

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    implicitHeight: 30
    implicitWidth: rowLayout.implicitWidth

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Process {
            id: cpuProc
            property int cpuUsage: 0
            property var lastCpuIdle: 0
            property var lastCpuTotal: 0
            command: ["sh", "-c", "head -1 /proc/stat"]

            stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    var p = data.trim().split(/\s+/)
                    var idle = parseInt(p[4]) + parseInt(p[5])
                    var total = p.slice(1, 8).reduce((a, b) => parseInt(a) + parseInt(b), 0)

                    if (cpuProc.lastCpuTotal > 0) {
                        cpuProc.cpuUsage = Math.round(
                            100 * (1 - (idle - cpuProc.lastCpuIdle) / (total - cpuProc.lastCpuTotal))
                        )
                    }

                    cpuProc.lastCpuTotal = total
                    cpuProc.lastCpuIdle = idle
                }
            }

            Component.onCompleted: running = true
        }

        RowLayout {
            spacing: 3

            Text {
                text: ""
                font.family: root.fontFamily
                font.pixelSize: root.fontSize

                color: {
                    if (cpuProc.cpuUsage > 85) return root.colRed
                    if (cpuProc.cpuUsage > 60) return root.colYellow
                    return root.colCyan
                }
            }

            Text {
                text: cpuProc.cpuUsage + "%"
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.colFg
            }
        }

        Rectangle {
            width: 1
            height: 16
            color: root.colMuted
            radius: 1
        }

        Process {
            id: memProc
            property int memUsage: 0
            command: ["sh", "-c", "free | grep Mem || echo '0 0 0 0'"]

            stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    var parts = data.trim().split(/\s+/)
                    var total = parseInt(parts[1]) || 1
                    var used = parseInt(parts[2]) || 0
                    memProc.memUsage = Math.round(100 * used / total)
                }
            }

            Component.onCompleted: running = true
        }

        RowLayout {
            spacing: 3

            Text {
                text: ""
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.colBlue
            }

            Text {
                text: memProc.memUsage + "%"
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                color: root.colFg
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true

            onTriggered: {
                cpuProc.running = true
                memProc.running = true
            }
        }
    }
}