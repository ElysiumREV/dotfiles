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

    function observeOutput(data) {
        if (data.includes("Agent registered"))
            agentRegistered = true;
        if (data.includes("Default agent request successful"))
            defaultAgentRequested = true;
        if (data.includes("Failed to register agent") || data.includes("No default controller available")) {
            registrationFailed = true;
            ready = false;
            status = data.trim();
        }
        if (/Enter PIN code|Request PIN code/i.test(data)) {
            promptType = "pin";
            promptText = data.trim() || "Digite o PIN solicitado pelo dispositivo.";
        } else if (/Confirm passkey|Authorize service|Request authorization/i.test(data)) {
            promptType = "confirm";
            promptText = data.trim() || "Confirme a solicitação de pareamento.";
        } else if (/Passkey:\s*\d+|PIN code:\s*\d+/i.test(data)) {
            promptType = "display";
            promptText = data.trim();
        }
        if (agentRegistered && defaultAgentRequested) {
            ready = true;
            status = "Agente pronto para confirmação e códigos de pareamento.";
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
        status = "Iniciando agente de pareamento…";
        agentProcess.running = true;
    }

    function release() {
        if (!agentProcess.running)
            return;
        intentionalStop = true;
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
            splitMarker: "\n"
            onRead: data => root.observeOutput(data)
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => root.observeOutput(data)
        }

        onStarted: {
            agentProcess.write("agent KeyboardDisplay\n");
            agentProcess.write("default-agent\n");
            readyTimer.restart();
        }

        onExited: (code) => {
            root.ready = false;
            if (root.intentionalStop) {
                root.intentionalStop = false;
                root.status = "";
            } else {
                root.status = code === 0 ? "Agente de pareamento encerrado." : "Não foi possível iniciar o agente Bluetooth.";
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
                root.status = "Agente pronto para confirmação e códigos de pareamento.";
            } else if (agentProcess.running && !root.ready) {
                // bluetoothctl output varies by BlueZ version and can omit these
                // acknowledgements. Keep pairing available if the interactive
                // client is alive; explicit registration errors still block it.
                if (!root.registrationFailed) {
                    root.ready = true;
                    root.status = "Agente Bluetooth ativo para pareamento.";
                } else {
                    root.status = "O Bluetooth recusou o registro do agente.";
                }
            }
        }
    }
}
