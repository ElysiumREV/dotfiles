pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool ready: false
    property bool agentRegistered: false
    property bool defaultAgentRequested: false
    property bool registrationFailed: false
    property bool intentionalStop: false
    property string status: ""
    property string promptType: ""
    property string promptText: ""
    property bool scanWanted: false

    function setScan(on) {
        scanWanted = on;
        if (agentProcess.running)
            agentProcess.write(on ? "scan bredr\n" : "scan off\n");
        else if (on)
            ensureStarted();  // onStarted sends the scan once the agent is up
    }

    function answerPrompt(value) {
        if (!agentProcess.running || promptType === "")
            return;
        agentProcess.write(value + "\n");
        promptType = "";
        promptText = "";
    }

    function cancelPrompt() {
        if (promptType === "display") {
            promptType = "";
            promptText = "";
            return;
        }
        answerPrompt(promptType === "pin" ? "" : "no");
    }

    // bluetoothctl redraws its prompt with ANSI codes and carriage returns, and prints
    // agent questions as a readline prompt with no trailing newline, so output is read
    // in raw chunks and split here instead of waiting for "\n".
    function observeChunk(chunk) {
        const clean = chunk.replace(/\x1b\[[0-9;]*[A-Za-z]/g, "");
        for (const piece of clean.split(/[\r\n]+/)) {
            const line = piece.replace(/^\s*\[[^\]]*\]>?\s*/, "").trim();
            if (line !== "")
                observeOutput(line);
        }
    }

    // Matches the agent strings of bluetoothctl (client/agent.c).
    function observeOutput(data) {
        if (data.includes("Agent registered"))
            agentRegistered = true;
        if (data.includes("Default agent request successful"))
            defaultAgentRequested = true;
        if (data.includes("Failed to register agent") || data.includes("No default controller available")) {
            registrationFailed = true;
            ready = false;
            status = data;
        }
        if (/Request canceled/i.test(data)) {
            promptType = "";
            promptText = "";
        } else if (/Enter PIN code|Enter passkey/i.test(data)) {
            promptType = "pin";
            promptText = /passkey/i.test(data) ? "Enter the passkey shown on the device." : "Enter the PIN requested by the device.";
        } else if (/Confirm passkey|Accept pairing|Authorize service/i.test(data)) {
            promptType = "confirm";
            promptText = data.replace(/\s*\(yes\/no\):?\s*$/i, "?");
        } else if (/^(Passkey|PIN code):\s*\d+/i.test(data)) {
            promptType = "display";
            promptText = "Type " + data.replace(/^.*:\s*/, "") + " on the device, then press Enter on it.";
        }
        if (agentRegistered && defaultAgentRequested) {
            ready = true;
            status = "Agent ready for pairing confirmations and codes.";
        }
    }

    function ensureStarted() {
        if (agentProcess.running) {
            if (!ready)
                readyTimer.restart();
            return;
        }
        ready = false;
        intentionalStop = false;
        agentRegistered = false;
        defaultAgentRequested = false;
        registrationFailed = false;
        status = "Starting pairing agent…";
        agentProcess.running = true;
    }

    function release() {
        if (!agentProcess.running)
            return;
        intentionalStop = true;
        scanWanted = false;  // BlueZ ends a client's discovery when it exits
        readyTimer.stop();
        agentProcess.running = false;
        ready = false;
        promptType = "";
        promptText = "";
        status = "";
    }

    Process {
        id: agentProcess

        command: ["bluetoothctl"]
        stdinEnabled: true

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.observeChunk(data)
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: data => root.observeChunk(data)
        }

        onStarted: {
            agentProcess.write("agent KeyboardDisplay\n");
            agentProcess.write("default-agent\n");
            if (root.scanWanted)
                agentProcess.write("scan bredr\n");
            readyTimer.restart();
        }

        onExited: (code) => {
            root.ready = false;
            if (root.intentionalStop) {
                root.intentionalStop = false;
                root.status = "";
            } else {
                root.status = code === 0 ? "Pairing agent stopped." : "Could not start the Bluetooth agent.";
            }
        }
    }

    Timer {
        id: readyTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (agentProcess.running && root.agentRegistered && root.defaultAgentRequested) {
                root.ready = true;
                root.status = "Agent ready for pairing confirmations and codes.";
            } else if (agentProcess.running && !root.ready) {
                // bluetoothctl output varies by BlueZ version and can omit these
                // acknowledgements. Keep pairing available if the interactive
                // client is alive; explicit registration errors still block it.
                if (!root.registrationFailed) {
                    root.ready = true;
                    root.status = "Bluetooth agent active for pairing.";
                } else {
                    root.status = "Bluetooth rejected the agent registration.";
                }
            }
        }
    }
}
