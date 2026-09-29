pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int cpuUsage: 0
    property int memoryUsage: 0
    property int swapUsage: 0
    property double memoryTotalKb: 0
    property double memoryAvailableKb: 0
    property double swapTotalKb: 0
    property double swapFreeKb: 0
    property double previousCpuTotal: 0
    property double previousCpuIdle: 0
    property var previousCoreStats: ({})
    property var cpuCores: []

    function parseStats(data) {
        const cpuLine = data.match(/^cpu\s+([^\n]+)/m)
        const totalMemoryMatch = data.match(/^MemTotal:\s+(\d+)/m)
        const availableMemoryMatch = data.match(/^MemAvailable:\s+(\d+)/m)
        const swapTotalMatch = data.match(/^SwapTotal:\s+(\d+)/m)
        const swapFreeMatch = data.match(/^SwapFree:\s+(\d+)/m)

        if (cpuLine) {
            const values = cpuLine[1].trim().split(/\s+/).slice(0, 8).map(Number)
            if (values.length >= 4 && values.every(Number.isFinite)) {
                const total = values.reduce((sum, value) => sum + value, 0)
                const idle = values[3] + (values[4] || 0)

                if (root.previousCpuTotal > 0 && total > root.previousCpuTotal) {
                    const totalDelta = total - root.previousCpuTotal
                    const idleDelta = idle - root.previousCpuIdle
                    root.cpuUsage = Math.max(0, Math.min(100,
                        Math.round(100 * (1 - idleDelta / totalDelta))))
                }

                root.previousCpuTotal = total
                root.previousCpuIdle = idle
            }
        }

        const nextCoreStats = ({})
        const nextCpuCores = []
        const lines = data.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^cpu(\d+)\s+(.+)$/)
            if (!match)
                continue

            const id = Number(match[1])
            const values = match[2].trim().split(/\s+/).slice(0, 8).map(Number)
            if (values.length < 4 || !values.every(Number.isFinite))
                continue

            const total = values.reduce((sum, value) => sum + value, 0)
            const idle = values[3] + (values[4] || 0)
            const previous = root.previousCoreStats[id]
            let usage = 0

            if (previous && total > previous.total) {
                const totalDelta = total - previous.total
                const idleDelta = idle - previous.idle
                usage = Math.max(0, Math.min(100,
                    Math.round(100 * (1 - idleDelta / totalDelta))))
            }

            nextCoreStats[id] = { total: total, idle: idle }
            nextCpuCores.push({ id: id, usage: usage })
        }

        root.previousCoreStats = nextCoreStats
        root.cpuCores = nextCpuCores

        if (totalMemoryMatch && availableMemoryMatch) {
            const total = Number(totalMemoryMatch[1])
            const available = Number(availableMemoryMatch[1])
            if (total > 0 && Number.isFinite(available)) {
                root.memoryTotalKb = total
                root.memoryAvailableKb = available
                root.memoryUsage = Math.max(0, Math.min(100,
                    Math.round(100 * (total - available) / total)))
            }
        }

        if (swapTotalMatch && swapFreeMatch) {
            const total = Number(swapTotalMatch[1])
            const free = Number(swapFreeMatch[1])
            root.swapTotalKb = total
            root.swapFreeKb = free
            root.swapUsage = total > 0
                ? Math.max(0, Math.min(100, Math.round(100 * (total - free) / total)))
                : 0
        }
    }

    Process {
        id: statsProcess
        command: ["cat", "/proc/stat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root.parseStats(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsProcess.running)
                statsProcess.running = true
        }
    }
}
