pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var pipewire: Pipewire

    // Only bind camera sources and their connected app streams. Updates come from
    // PipeWire's graph changes; no timer or process polling is needed.
    readonly property var cameraCaptureLinks: pipewire.linkGroups.values.filter(group =>
        group.source?.type === "Video/Source"
            && group.target?.isStream && group.target?.isSink)

    readonly property var cameraApplications: {
        const names = new Set();
        for (const group of cameraCaptureLinks) {
            if (group.state !== PwLinkState.Active)
                continue;

            const target = group.target;
            if (!target?.ready)
                continue;

            const properties = target.properties ?? {};
            const name = properties["application.name"] || properties["media.name"]
                || target.description || target.name;
            if (name)
                names.add(String(name));
        }
        return Array.from(names).sort((a, b) => a.localeCompare(b));
    }

    PwObjectTracker {
        objects: {
            const nodes = [];
            for (const group of root.cameraCaptureLinks) {
                nodes.push(group.source);
                nodes.push(group.target);
            }
            return nodes;
        }
    }
}
