pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int historyLimit: 50
    readonly property int summaryCharacterLimit: 512
    readonly property int bodyCharacterLimit: 4096
    property var activeNotifications: []
    property var popupNotifications: []
    property var history: []
    property bool doNotDisturb: false
    property bool centerVisible: false
    property var centerMonitor: null
    property string centerRequestedTab: "notifications"
    property bool centerCalendarCollapsed: false
    property var closingIds: ({})
    readonly property var historyGroups: {
        const groups = [];
        for (const item of history) {
            let group = groups.find(entry => entry.appName === item.appName);
            if (!group) {
                group = { appName: item.appName, appIcon: item.appIcon, notifications: [] };
                groups.push(group);
            }
            group.notifications.push(item);
        }
        return groups;
    }

    function boundedText(value, limit) {
        const text = String(value || "");
        return text.length > limit ? text.slice(0, limit) + "…" : text;
    }

    function receive(notification) {
        if (!notification || !notification.id)
            return;

        // The same instance may be re-emitted (for example, on reloads).
        // Connect once per object and capture only the ID, without retaining the notification.
        const alreadyActive = activeNotifications.some(item => item === notification);
        if (!alreadyActive) {
            const notificationId = notification.id;
            notification.closed.connect(() => root.handleClosed(notificationId));
        }

        notification.tracked = true;

        // Remove the old duplicate if any (same ID updated)
        activeNotifications = activeNotifications.filter(item => item.id !== notification.id).concat([notification]);

        if (!notification.transient) {
            const record = {
                id: notification.id,
                appName: notification.appName || notification.desktopEntry || "Notification",
                appIcon: iconNameOf(notification),
                summary: boundedText(notification.summary, summaryCharacterLimit),
                body: boundedText(notification.body, bodyCharacterLimit),
                urgency: notification.urgency,
                actions: notification.actions || [],
                notification: notification,
                timestamp: Date.now(),
                unread: !centerVisible,
                active: true
            };

            const nextHistory = [record].concat(history.filter(item => item.id !== record.id));
            if (nextHistory.length > historyLimit) {
                const evicted = nextHistory.slice(historyLimit);
                for (const item of evicted) {
                    if (item.notification) {
                        if (item.active && !closingIds[item.id]) {
                            closingIds[item.id] = true;
                            try {
                                item.notification.dismiss();
                            } catch (e) {}
                        }
                    }
                }
                history = nextHistory.slice(0, historyLimit);
            } else {
                history = nextHistory;
            }
        }

        if (!doNotDisturb && !centerVisible) {
            popupNotifications = popupNotifications.filter(item => item.id !== notification.id)
                .concat([notification]).slice(-historyLimit);
        }
    }

    function findActive(id) {
        return activeNotifications.find(item => item && item.id === id) ?? null;
    }

    function removePopup(id) {
        popupNotifications = popupNotifications.filter(item => item && item.id !== id);
    }

    function expirePopup(id) {
        const notification = findActive(id);
        removePopup(id);
        if (!notification)
            return;

        // Expiration closes the live notification but leaves its history record.
        try {
            notification.expire();
        } catch (e) {
            notification.dismiss();
        }
    }

    function dismiss(id) {
        if (closingIds[id])
            return;
        closingIds[id] = true;

        const notification = findActive(id);
        removePopup(id);

        history = history.filter(item => {
            if (item.id === id)
                return false;
            return true;
        });

        if (notification) {
            try {
                notification.dismiss();
            } catch (e) {}
        }
        // Release the lock after the current event loop so future dismisses work.
        Qt.callLater(() => {
            delete closingIds[id];
        });
    }

    function handleClosed(id) {
        closingIds[id] = true;

        activeNotifications = activeNotifications.filter(item => item && item.id !== id);
        removePopup(id);

        history = history.map(item => {
            if (item.id !== id)
                return item;
            return {
                id: item.id,
                appName: item.appName,
                appIcon: item.appIcon,
                summary: item.summary,
                body: item.body,
                urgency: item.urgency,
                actions: [],
                notification: null,
                timestamp: item.timestamp,
                unread: item.unread,
                active: false
            };
        });

        // Releases the lock after the QML event loop cycle
        Qt.callLater(() => {
            delete closingIds[id];
        });
    }

    function clearHistory() {
        const active = activeNotifications.slice();
        activeNotifications = [];
        popupNotifications = [];

        for (const item of history) {
            if (item.notification) {
                item.notification = null;
            }
        }
        history = [];

        for (const notification of active) {
            if (!notification)
                continue;
            closingIds[notification.id] = true;
            try {
                notification.dismiss();
            } catch (e) {}
        }

        Qt.callLater(() => {
            closingIds = ({});
        });
    }

    function markAllRead() {
        history = history.map(item => {
            if (!item.unread)
                return item;
            return {
                id: item.id,
                appName: item.appName,
                appIcon: item.appIcon,
                summary: item.summary,
                body: item.body,
                urgency: item.urgency,
                actions: item.actions,
                notification: item.notification,
                timestamp: item.timestamp,
                unread: false,
                active: item.active
            };
        });
    }

    // Quickshell exposes both the app_icon parameter and the image-path hint as
    // `image` = "image://icon/<name or path>", so a plain app icon would look like an
    // attached picture. These helpers tell them apart: icon names and files stored in
    // icon directories are app icons; other files and image-data are real images.
    function embeddedImage(notification) {
        const image = String(notification.image ?? "");
        return image.startsWith("image://icon/") ? image.slice("image://icon/".length) : null;
    }

    function isIconPath(path) {
        return /\/(icons|pixmaps)\//.test(path);
    }

    function iconNameOf(notification) {
        if (notification.appIcon)
            return notification.appIcon;
        const embedded = embeddedImage(notification);
        if (embedded === null)
            return "";
        return !embedded.startsWith("/") || isIconPath(embedded) ? embedded : "";
    }

    // Resolves the icon name to something loadable; "" when the theme has no such icon
    // (the image provider would otherwise return a blank image).
    function iconSourceOf(notification) {
        const name = iconNameOf(notification);
        if (name === "")
            return "";
        if (name.startsWith("/"))
            return "file://" + name;
        if (name.includes(":"))
            return name;
        return Quickshell.iconPath(name, true);
    }

    function attachmentOf(notification) {
        const embedded = embeddedImage(notification);
        if (embedded === null)
            return String(notification.image ?? "");
        return embedded.startsWith("/") && !isIconPath(embedded) ? "file://" + embedded : "";
    }

    function toggleCenter(monitor, tab) {
        const requestedTab = tab || "notifications";
        if (centerVisible && centerMonitor === monitor && centerRequestedTab === requestedTab) {
            centerVisible = false;
            centerMonitor = null;
            return;
        }
        openCenter(monitor, requestedTab);
    }

    function openCenter(monitor, tab) {
        centerRequestedTab = tab || "notifications";
        centerMonitor = monitor;
        centerVisible = true;
        // The unified panel marks the history as read when opened.
    }

    function closeCenter() {
        centerVisible = false;
        centerMonitor = null;
        centerRequestedTab = "notifications";
    }

    onDoNotDisturbChanged: {
        if (doNotDisturb)
            popupNotifications = [];
    }

    onCenterVisibleChanged: {
        if (centerVisible)
            popupNotifications = [];
    }

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        keepOnReload: true
        onNotification: notification => root.receive(notification)
    }
}
