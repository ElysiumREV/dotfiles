import QtQuick
import ".." as Config

// Shared enter/exit animation for popups and overlays.
//
// Two progress channels:
//   progress    -> opacity and offset, curve without overshoot
//   popProgress -> scale only, with overshoot controlled by the fast spatial curve
//
// The surface must:
//   1. implement close() by calling requestClose()
//   2. hide the window in onExitFinished() (because `visible` may be a binding
//      in overlays tied to WindowControl, and writing to it would break the binding)
QtObject {
    id: root

    required property var popup

    // Emitted when the exit animation finishes; the surface hides the window here.
    signal exitFinished()

    property real progress: 0
    property real popProgress: 0

    readonly property bool closing: internalClosing
    property bool internalClosing: false

    // Initial card values.
    property real startScale: 0.96
    property real startOffset: -8

    // Fullscreen overlays take longer than popups anchored to the bar.
    property int inDuration: Config.Theme.durPopupIn
    property int outDuration: Config.Theme.durPopupOut

    readonly property real contentOpacity: progress
    readonly property real contentScale: startScale + (1 - startScale) * popProgress
    readonly property real contentOffsetY: startOffset * (1 - progress)

    // Enter animation. Assumes the window is already visible: the opener decides how.
    function playIn() {
        internalClosing = false;
        closeOpacity.stop();
        closePop.stop();
        enterOpacity.restart();
        enterPop.restart();
    }

    // Exit animation. Idempotent.
    function requestClose() {
        if (internalClosing) return;
        internalClosing = true;
        enterOpacity.stop();
        enterPop.stop();
        closeOpacity.restart();
        closePop.restart();
    }

    // Pointer re-entry during exit: go back to open.
    function cancelClose() {
        if (!internalClosing) return;
        internalClosing = false;
        closeOpacity.stop();
        closePop.stop();
        enterOpacity.restart();
        enterPop.restart();
    }

    // Window hidden by another path: reset without animating.
    function reset() {
        internalClosing = false;
        enterOpacity.stop();
        enterPop.stop();
        closeOpacity.stop();
        closePop.stop();
        progress = 0;
        popProgress = 0;
    }

    NumberAnimation {
        id: enterOpacity
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.inDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveEnter
    }

    NumberAnimation {
        id: enterPop
        target: root
        property: "popProgress"
        from: 0
        to: 1
        duration: root.inDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveSpatialFast
    }

    NumberAnimation {
        id: closeOpacity
        target: root
        property: "progress"
        from: root.progress
        to: 0
        duration: root.outDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveExit
        onFinished: {
            if (!root.internalClosing) return;
            root.internalClosing = false;
            root.progress = 0;
            root.popProgress = 0;
            root.exitFinished();
        }
    }

    NumberAnimation {
        id: closePop
        target: root
        property: "popProgress"
        from: root.popProgress
        to: 0
        duration: root.outDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveExit
    }
}
