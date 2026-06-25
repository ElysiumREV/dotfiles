import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import ".." as Config

Item {
    id: root

    implicitHeight: Config.Theme.moduleHeight
    implicitWidth: rowLayout.implicitWidth

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.Theme.moduleSpacing

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
            spacing: Config.Theme.moduleTightSpacing

            Text {
                text: ""
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize

                color: {
                    if (cpuProc.cpuUsage > 85) return Config.Theme.colRed
                    if (cpuProc.cpuUsage > 60) return Config.Theme.colYellow
                    return Config.Theme.colHighlight
                }
            }

            Text {
                text: cpuProc.cpuUsage + "%"
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                color: Config.Theme.colFg
            }
        }

        Rectangle {
            width: Config.Theme.separatorWidth
            height: Config.Theme.separatorHeight
            color: Config.Theme.colMuted
            radius: Config.Theme.separatorRadius
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
            spacing: Config.Theme.moduleTightSpacing

            Text {
                text: ""
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                color: Config.Theme.colHighlight
            }

            Text {
                text: memProc.memUsage + "%"
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                color: Config.Theme.colFg
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
