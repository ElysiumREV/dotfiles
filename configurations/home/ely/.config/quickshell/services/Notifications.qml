pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int historyLimit: 50
    property var activeNotifications: []
    property var popupNotifications: []
    property var history: []
    property bool doNotDisturb: false
    property bool centerVisible: false
    property var centerMonitor: null
    readonly property int unreadCount: history.filter(item => item.unread).length

    function receive(notification) {
        notification.tracked = true;
        activeNotifications = activeNotifications.concat([notification]);

        if (!notification.transient) {
            const record = {
                id: notification.id,
                appName: notification.appName || notification.desktopEntry || "Notificação",
                appIcon: notification.appIcon || "",
                summary: notification.summary || "",
                body: notification.body || "",
                urgency: notification.urgency,
                actions: notification.actions,
                notification: notification,
                timestamp: Date.now(),
                unread: !centerVisible,
                active: true
            };
            history = [record].concat(history.filter(item => item.id !== record.id))
                .slice(0, historyLimit);
        }

        if (!doNotDisturb) {
            popupNotifications = popupNotifications.concat([notification]).slice(-historyLimit);
        }
    }

    function findActive(id) {
        return activeNotifications.find(item => item.id === id) ?? null;
    }

    function removePopup(id) {
        popupNotifications = popupNotifications.filter(item => item.id !== id);
    }

    function expirePopup(id) {
        const notification = findActive(id);
        removePopup(id);
        if (notification)
            notification.expire();
    }

    function dismiss(id) {
        const notification = findActive(id);
        removePopup(id);
        history = history.filter(item => item.id !== id);
        if (notification)
            notification.dismiss();
    }

    function archiveFromPopup(id) {
        const notification = findActive(id);
        removePopup(id);
        history = history.map(item => {
            if (item.id !== id || !item.unread)
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
        if (notification)
            notification.dismiss();
    }

    function handleClosed(id) {
        activeNotifications = activeNotifications.filter(item => item.id !== id);
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
    }

    function clearHistory() {
        const active = activeNotifications.slice();
        popupNotifications = [];
        history = [];
        for (const notification of active)
            notification.dismiss();
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

    function toggleCenter(monitor) {
        if (centerVisible && centerMonitor === monitor) {
            centerVisible = false;
            centerMonitor = null;
            return;
        }
        centerMonitor = monitor;
        centerVisible = true;
        markAllRead();
    }

    function closeCenter() {
        centerVisible = false;
        centerMonitor = null;
    }

    onDoNotDisturbChanged: {
        if (doNotDisturb)
            popupNotifications = [];
    }

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        keepOnReload: true
        onNotification: notification => root.receive(notification)
    }

    Instantiator {
        model: root.activeNotifications
        delegate: Connections {
            target: modelData
            function onClosed(reason) {
                if (target)
                    root.handleClosed(target.id);
            }
        }
    }
}
