pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import ".." as Config

// DNS for NetworkManager connections, used by the Wi-Fi panel.
//
// A default (Preferences.dns.defaultMode) applies to every saved Wi-Fi/Ethernet
// profile; per-network exceptions (Preferences.dns.overrides, by connection
// UUID) win over it, e.g. a campus Wi-Fi whose login page needs the network's
// own DNS. Choices are written into each NetworkManager profile through
// scripts/dns.sh (nmcli), so they keep working without the shell; networks
// joined later get the default when they connect.
Singleton {
    id: root

    readonly property var providers: [
        { id: "cloudflare", label: "Cloudflare", detail: "1.1.1.1",
          ipv4: ["1.1.1.1", "1.0.0.1"],
          ipv6: ["2606:4700:4700::1111", "2606:4700:4700::1001"] },
        { id: "quad9", label: "Quad9", detail: "9.9.9.9 · blocks malware",
          ipv4: ["9.9.9.9", "149.112.112.112"],
          ipv6: ["2620:fe::fe", "2620:fe::9"] },
        { id: "google", label: "Google", detail: "8.8.8.8",
          ipv4: ["8.8.8.8", "8.8.4.4"],
          ipv6: ["2001:4860:4860::8888", "2001:4860:4860::8844"] },
        { id: "adguard", label: "AdGuard", detail: "94.140.14.14 · blocks ads",
          ipv4: ["94.140.14.14", "94.140.15.15"],
          ipv6: ["2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff"] }
    ]

    readonly property string script: Quickshell.shellPath("scripts/dns.sh")
    readonly property var prefs: Config.Preferences.dns

    // ---- State of the active Wi-Fi connection (from `dns.sh status`)
    property bool loaded: false
    property string activeUuid: ""
    property string connectionName: ""
    property var configuredIpv4: []
    property var configuredIpv6: []
    property bool ignoresNetworkDns: false
    property var currentServers: []
    readonly property var activeSpec: specFromProfile(ignoresNetworkDns, configuredIpv4, configuredIpv6)

    // ---- Choices
    readonly property var defaultSpec: specFromPrefs(prefs.defaultMode, prefs.defaultIpv4, prefs.defaultIpv6)
    readonly property var activeOverride: activeUuid !== "" ? (prefs.overrides[activeUuid] ?? null) : null
    // What the active network's combo shows: "default" or the exception's mode.
    readonly property string networkChoice: activeOverride ? activeOverride.mode : "default"

    property bool busy: false
    property string errorText: ""
    property var queue: []
    // Last automatic sync per connection, so a failing apply is not retried in a loop.
    property var lastSync: ({})

    // ---- Login pages (captive portals)
    readonly property bool usesFixedDns: activeSpec.mode !== "auto"
    readonly property bool connectivityProblem: Networking.connectivity === NetworkConnectivity.Portal
        || Networking.connectivity === NetworkConnectivity.Limited
    readonly property bool portalSuspected: loaded && activeUuid !== "" && usesFixedDns && connectivityProblem
    // Connectivity is briefly "limited" while any network is still connecting, so
    // the warning (and its notification) only appears if the problem persists.
    property bool showPortalHint: false
    onPortalSuspectedChanged: {
        if (portalSuspected) {
            portalDelay.restart();
        } else {
            portalDelay.stop();
            showPortalHint = false;
        }
    }
    property var portalNotified: ({})

    function label(mode) {
        if (mode === "auto")
            return "Automatic";
        if (mode === "custom")
            return "Custom";
        return providers.find(item => item.id === mode)?.label ?? "Custom";
    }

    function sameList(a, b) {
        return a.length === b.length && a.every(value => b.indexOf(value) !== -1);
    }

    function splitList(text) {
        return String(text || "").split(/[\s,;]+/).map(item => item.trim()).filter(Boolean);
    }

    function isIPv4(value) {
        const parts = value.split(".");
        return parts.length === 4 && parts.every(part => /^\d{1,3}$/.test(part) && Number(part) <= 255);
    }

    function isIPv6(value) {
        if (!/^[0-9a-fA-F:]+$/.test(value) || value.indexOf(":") === -1)
            return false;
        const doubleColons = value.split("::").length - 1;
        if (doubleColons > 1)
            return false;
        const groups = value.split(":").filter(group => group !== "");
        if (!groups.every(group => group.length <= 4))
            return false;
        return doubleColons === 1 ? groups.length < 8 : groups.length === 8;
    }

    // "" when the custom servers are valid, otherwise a message for the user.
    function validate(ipv4Text, ipv6Text) {
        const ipv4 = splitList(ipv4Text);
        const ipv6 = splitList(ipv6Text);
        if (ipv4.length === 0 && ipv6.length === 0)
            return "Enter at least one DNS server.";
        const badIpv4 = ipv4.find(value => !isIPv4(value));
        if (badIpv4)
            return "“" + badIpv4 + "” is not a valid IPv4 address.";
        const badIpv6 = ipv6.find(value => !isIPv6(value));
        if (badIpv6)
            return "“" + badIpv6 + "” is not a valid IPv6 address.";
        return "";
    }

    // { mode, ipv4[], ipv6[] }
    function specFromPrefs(mode, ipv4Text, ipv6Text) {
        const provider = providers.find(item => item.id === mode);
        if (provider)
            return { mode: mode, ipv4: provider.ipv4, ipv6: provider.ipv6 };
        if (mode === "custom")
            return { mode: "custom", ipv4: splitList(ipv4Text), ipv6: splitList(ipv6Text) };
        return { mode: "auto", ipv4: [], ipv6: [] };
    }

    function specFromProfile(ignoresAuto, ipv4, ipv6) {
        if (!ignoresAuto && ipv4.length === 0 && ipv6.length === 0)
            return { mode: "auto", ipv4: [], ipv6: [] };
        const provider = providers.find(item => sameList(item.ipv4, ipv4));
        return { mode: provider ? provider.id : "custom", ipv4: ipv4, ipv6: ipv6 };
    }

    function effectiveFor(uuid) {
        const override = prefs.overrides[uuid];
        return override ? specFromPrefs(override.mode, override.ipv4, override.ipv6) : defaultSpec;
    }

    // The profile matches the spec (IPv6 is only compared when the spec sets it
    // and the profile kept it; networks with IPv6 disabled store no IPv6 DNS).
    function matches(actual, spec) {
        if (spec.mode === "auto")
            return actual.mode === "auto";
        if (actual.mode === "auto" || !sameList(actual.ipv4, spec.ipv4))
            return false;
        return actual.ipv6.length === 0 || sameList(actual.ipv6, spec.ipv6);
    }

    function argsFor(spec, uuid) {
        return spec.mode === "auto" ? ["reset", uuid] : ["set", spec.ipv4.join(","), spec.ipv6.join(","), uuid];
    }

    // ---- Public actions (return "" or an error message)

    function setDefault(mode, ipv4Text, ipv6Text) {
        if (mode === "custom") {
            const error = validate(ipv4Text, ipv6Text);
            if (error !== "")
                return error;
        }
        prefs.defaultMode = mode;
        prefs.defaultIpv4 = mode === "custom" ? splitList(ipv4Text).join(", ") : "";
        prefs.defaultIpv6 = mode === "custom" ? splitList(ipv6Text).join(", ") : "";
        // Write it into every saved profile that has no exception.
        errorText = "";
        busy = true;
        profilesProcess.exec(["bash", script, "profiles"]);
        return "";
    }

    // mode "default" removes this network's exception.
    function setNetworkChoice(mode, ipv4Text, ipv6Text) {
        if (activeUuid === "")
            return "No active Wi-Fi connection.";
        if (mode === "custom") {
            const error = validate(ipv4Text, ipv6Text);
            if (error !== "")
                return error;
        }
        errorText = "";
        const next = Object.assign({}, prefs.overrides);
        if (mode === "default") {
            delete next[activeUuid];
        } else {
            next[activeUuid] = {
                name: connectionName,
                mode: mode,
                ipv4: mode === "custom" ? splitList(ipv4Text).join(", ") : "",
                ipv6: mode === "custom" ? splitList(ipv6Text).join(", ") : ""
            };
        }
        prefs.overrides = next;
        enqueue([argsFor(effectiveFor(activeUuid), activeUuid)]);
        return "";
    }

    function useNetworkDnsHere() {
        setNetworkChoice("auto", "", "");
    }

    function refresh() {
        if (!statusProcess.running)
            statusProcess.exec(["bash", script, "status"]);
    }

    // ---- Internals

    function enqueue(jobs) {
        queue = queue.concat(jobs);
        runNext();
    }

    function runNext() {
        if (changeProcess.running)
            return;
        if (queue.length === 0) {
            busy = false;
            refresh();
            return;
        }
        busy = true;
        const job = queue[0];
        queue = queue.slice(1);
        changeProcess.exec(["bash", script].concat(job));
    }

    // Brings the active network in line with its choice. Runs after every status read.
    function syncActive() {
        if (!Config.Preferences.loaded || busy || activeUuid === "")
            return;
        // A fixed DNS set before (by an older version of this menu, or by hand)
        // while the default is automatic becomes this network's exception
        // instead of being reset.
        if (!activeOverride && defaultSpec.mode === "auto" && activeSpec.mode !== "auto") {
            const next = Object.assign({}, prefs.overrides);
            next[activeUuid] = {
                name: connectionName,
                mode: activeSpec.mode,
                ipv4: activeSpec.mode === "custom" ? activeSpec.ipv4.join(", ") : "",
                ipv6: activeSpec.mode === "custom" ? activeSpec.ipv6.join(", ") : ""
            };
            prefs.overrides = next;
            return;
        }
        const spec = effectiveFor(activeUuid);
        if (matches(activeSpec, spec))
            return;
        const key = JSON.stringify(spec);
        if (lastSync[activeUuid] === key)
            return; // already tried; do not loop on a failure
        const attempts = Object.assign({}, lastSync);
        attempts[activeUuid] = key;
        lastSync = attempts;
        enqueue([argsFor(spec, activeUuid)]);
    }

    function parse(text) {
        const result = {};
        for (const line of String(text).split("\n")) {
            const index = line.indexOf("=");
            if (index > 0)
                result[line.slice(0, index)] = line.slice(index + 1);
        }
        return result;
    }

    onShowPortalHintChanged: {
        if (!showPortalHint || portalNotified[activeUuid])
            return;
        const notified = Object.assign({}, portalNotified);
        notified[activeUuid] = true;
        portalNotified = notified;
        portalNotification.exec(["notify-send", "-a", "Network", "-i", "network-wireless",
            "-A", "auto=Use network DNS", "--wait",
            "No internet on “" + connectionName + "”",
            "This network may have a login page that only works with its own DNS ("
                + label(activeSpec.mode) + " is in use)."]);
    }

    Timer {
        id: portalDelay
        interval: 6000
        repeat: false
        onTriggered: root.showPortalHint = root.portalSuspected
    }

    Connections {
        target: WifiControl
        function onActiveNetworkChanged() {
            root.refresh();
        }
        function onExpandedChanged() {
            if (WifiControl.expanded)
                root.refresh();
        }
    }

    Connections {
        target: Config.Preferences
        function onLoadedChanged() {
            root.syncActive();
        }
    }

    Component.onCompleted: refresh()

    Process {
        id: statusProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const status = root.parse(text);
                root.loaded = true;
                if (status.error) {
                    root.activeUuid = "";
                    root.connectionName = "";
                    root.configuredIpv4 = [];
                    root.configuredIpv6 = [];
                    root.ignoresNetworkDns = false;
                    root.currentServers = [];
                    return;
                }
                root.activeUuid = status.uuid ?? "";
                root.connectionName = status.name ?? "";
                root.configuredIpv4 = root.splitList(status.ipv4_dns);
                root.configuredIpv6 = root.splitList(status.ipv6_dns);
                root.ignoresNetworkDns = status.ipv4_ignore_auto === "yes";
                // Link-local addresses (fe80::) are not useful to show.
                root.currentServers = root.splitList(status.current)
                    .filter(server => !server.toLowerCase().startsWith("fe80:"));
                root.syncActive();
            }
        }
    }

    // Applying a new default: every saved profile without an exception.
    Process {
        id: profilesProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const jobs = [];
                for (const line of String(text).split("\n")) {
                    const uuid = line.split("\t")[0];
                    if (uuid && !root.prefs.overrides[uuid])
                        jobs.push(root.argsFor(root.defaultSpec, uuid));
                }
                root.busy = false;
                root.lastSync = ({});
                root.enqueue(jobs);
            }
        }
    }

    Process {
        id: changeProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.parse(text);
                if (result.error)
                    root.errorText = result.error;
                else if (!result.ok)
                    root.errorText = "Could not change the DNS.";
            }
        }
        onExited: root.runNext()
    }

    // The notification's button answers on stdout ("auto") when clicked.
    Process {
        id: portalNotification
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "auto")
                    root.useNetworkDnsHere();
            }
        }
    }
}
