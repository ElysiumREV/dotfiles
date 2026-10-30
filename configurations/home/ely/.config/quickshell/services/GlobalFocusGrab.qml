pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    signal dismissed()

    // Persistent windows (the bar) remain part of the grab when a panel has
    // keyboard focus. Dismissable windows join only while they are visible.
    property var persistentWindows: []
    property var dismissableWindows: []

    function addPersistent(window): void {
        if (!window || persistentWindows.indexOf(window) !== -1)
            return;
        persistentWindows = persistentWindows.concat([window]);
    }

    function removePersistent(window): void {
        persistentWindows = persistentWindows.filter(item => item !== window);
    }

    function addDismissable(window): void {
        if (!window || dismissableWindows.indexOf(window) !== -1)
            return;
        dismissableWindows = dismissableWindows.concat([window]);
    }

    function removeDismissable(window): void {
        dismissableWindows = dismissableWindows.filter(item => item !== window);
    }

    function hasActiveFocus(item): bool {
        if (!item)
            return false;
        if (item.activeFocus)
            return true;

        const children = item.children ?? [];
        for (const child of children) {
            if (hasActiveFocus(child))
                return true;
        }
        return false;
    }

    function dismiss(): void {
        dismissableWindows = [];
        dismissed();
    }

    HyprlandFocusGrab {
        id: grab

        readonly property var visibleDismissable: root.dismissableWindows.filter(window => window?.visible)
        readonly property bool hasFocusedDismissable: visibleDismissable.some(window =>
            root.hasActiveFocus(window.contentItem))

        windows: {
            const all = visibleDismissable.every(window => !window.focusable);
            return all || hasFocusedDismissable
                ? visibleDismissable.concat(root.persistentWindows)
                : visibleDismissable;
        }
        active: visibleDismissable.length > 0
        onCleared: root.dismiss()
    }
}
