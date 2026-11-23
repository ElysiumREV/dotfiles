pragma Singleton

import QtQuick
import Quickshell

// Context profiles: one click changes several settings together.
//
// Profiles are toggles. Turning one on remembers the current Do Not Disturb,
// power profile and brightness; turning it off restores them. Switching
// between profiles starts from those remembered values, so a setting that the
// new profile does not touch goes back to what it was before any profile.
// The active profile lasts for the session (like Do Not Disturb).
Singleton {
    id: root

    // null = leave the setting alone
    readonly property var profiles: [
        { id: "focus", label: "Focus", icon: "center_focus_strong",
          dnd: true, power: null, brightness: null },
        { id: "gaming", label: "Gaming", icon: "sports_esports",
          dnd: true, power: "performance", brightness: null },
        { id: "battery", label: "Battery", icon: "battery_saver",
          dnd: null, power: "power-saver", brightness: 0.3 }
    ]

    property string active: ""
    property var saved: null
    readonly property var activeProfile: profiles.find(profile => profile.id === active) ?? null

    function profile(id) {
        return profiles.find(item => item.id === id) ?? null;
    }

    // What a profile changes, e.g. "Do Not Disturb · Performance".
    function summary(id) {
        const item = profile(id);
        if (!item)
            return "";
        const parts = [];
        if (item.dnd !== null)
            parts.push(item.dnd ? "Do Not Disturb" : "Notifications on");
        if (item.power !== null && PowerProfiles.availableProfiles.includes(item.power))
            parts.push(PowerProfiles.getProfileLabel(item.power));
        if (item.brightness !== null && Brightness.supported)
            parts.push("Brightness " + Math.round(item.brightness * 100) + "%");
        return parts.join(" · ");
    }

    function currentState() {
        return {
            dnd: Notifications.doNotDisturb,
            power: PowerProfiles.activeProfile,
            brightness: Brightness.supported ? Brightness.brightness : null
        };
    }

    function applyState(state) {
        if (state.dnd !== null && state.dnd !== undefined)
            Notifications.doNotDisturb = state.dnd;
        if (state.power && PowerProfiles.availableProfiles.includes(state.power))
            PowerProfiles.setProfile(state.power);
        if (state.brightness !== null && state.brightness !== undefined && Brightness.supported)
            Brightness.setBrightness(state.brightness);
    }

    function activate(id) {
        const item = profile(id);
        if (!item)
            return;
        if (active === "")
            saved = currentState();
        // Start from the remembered settings; the profile overrides what it sets.
        applyState({
            dnd: item.dnd ?? saved.dnd,
            power: item.power ?? saved.power,
            brightness: item.brightness ?? saved.brightness
        });
        active = id;
    }

    function deactivate() {
        if (active === "")
            return;
        if (saved)
            applyState(saved);
        saved = null;
        active = "";
    }

    function toggle(id) {
        if (active === id)
            deactivate();
        else
            activate(id);
    }
}
