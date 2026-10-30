import QtQuick
import "../services" as Services

Item {
    id: root

    visible: false
    width: 0
    height: 0

    required property var window
    property var dismissAction
    property bool active: true

    function syncRegistration(): void {
        if (!window)
            return;
        if (window.visible && active)
            Services.GlobalFocusGrab.addDismissable(window);
        else
            Services.GlobalFocusGrab.removeDismissable(window);
    }

    function dismissWindow(): void {
        if (!window?.visible || !active)
            return;
        if (typeof dismissAction === "function")
            dismissAction();
        else
            window.visible = false;
    }

    Component.onCompleted: syncRegistration()
    onActiveChanged: syncRegistration()
    Component.onDestruction: {
        if (window)
            Services.GlobalFocusGrab.removeDismissable(window);
    }

    Connections {
        target: root.window
        ignoreUnknownSignals: true
        function onVisibleChanged(): void { root.syncRegistration(); }
    }

    Connections {
        target: Services.GlobalFocusGrab
        function onDismissed(): void { root.dismissWindow(); }
    }
}
