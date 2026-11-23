import QtQuick

// Turns wheel deltas into whole steps. A mouse wheel sends 120 per notch, but a
// touchpad sends many small deltas; acting on every event would skip several
// workspaces/tracks or jump the volume on a single swipe.
QtObject {
    property real pending: 0
    property int threshold: 120

    // Adds a delta and returns how many whole steps (signed) it completed.
    function feed(delta) {
        if (!delta)
            return 0;
        // Changing direction drops the leftover from the other way.
        if (pending !== 0 && Math.sign(pending) !== Math.sign(delta))
            pending = 0;
        pending += delta;
        const steps = Math.trunc(pending / threshold);
        pending -= steps * threshold;
        return steps;
    }
}
