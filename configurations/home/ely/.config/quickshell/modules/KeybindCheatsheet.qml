import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import ".." as Config
import "../widgets" as Widgets

Scope {
    id: root

    property bool active: false
    property var targetMonitor: null
    property var bindings: []
    property string searchText: ""
    property string loadError: ""
    property bool loading: false
    property var previousToplevel: null

    readonly property var filteredBindings: {
        const query = normalize(searchText);
        const result = bindings.map(binding => formatBinding(binding));
        result.sort((a, b) => a.category.localeCompare(b.category)
            || a.action.localeCompare(b.action)
            || a.shortcut.localeCompare(b.shortcut));
        if (!query)
            return result;
        return result.filter(binding => normalize(
            `${binding.shortcut} ${binding.category} ${binding.action}`
        ).includes(query));
    }

    function normalize(value) {
        return (value ?? "").toString().normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase().trim();
    }

    function modifierNames(mask) {
        const names = [];
        if (mask & (1 << 2)) names.push("Ctrl");
        if (mask & (1 << 6)) names.push("Super");
        if (mask & (1 << 0)) names.push("Shift");
        if (mask & (1 << 3)) names.push("Alt");
        if (mask & (1 << 1)) names.push("Caps");
        if (mask & (1 << 4)) names.push("Mod2");
        if (mask & (1 << 5)) names.push("Mod3");
        if (mask & (1 << 7)) names.push("Mod5");
        return names;
    }

    function displayKey(binding) {
        let key = (binding.key ?? "").toString();
        if (!key && binding.keycode)
            key = `Keycode ${binding.keycode}`;
        const substitutions = {
            "Return": "Enter",
            "Escape": "Esc",
            "Slash": "/",
            "mouse:272": "Mouse 1",
            "mouse:273": "Mouse 2",
            "mouse_up": "Scroll ↑",
            "mouse_down": "Scroll ↓"
        };
        return (substitutions[key] ?? key) || "Tecla desconhecida";
    }

    function categoryFor(binding, description) {
        if (description.includes(":"))
            return description.slice(0, description.indexOf(":")).trim();

        const dispatcher = (binding.dispatcher ?? "").toString().toLowerCase();
        if (["workspace", "movetoworkspace", "togglespecialworkspace"].includes(dispatcher))
            return "Workspaces";
        if (["movefocus", "movewindow", "resizeactive", "fullscreen", "togglefloating",
                "togglesplit", "killactive", "closewindow", "pseudo"].includes(dispatcher))
            return "Janelas";
        if (dispatcher === "exec") {
            const command = (binding.arg ?? "").toString().toLowerCase();
            if (command.includes("playerctl") || command.includes("volume")
                    || command.includes("brightness") || command.includes("wpctl"))
                return "Mídia e controles";
            if (command.includes("screenshot") || command.includes("wallpaper")
                    || command.includes("clipboard"))
                return "QuickShell";
            return "Aplicativos e sistema";
        }
        return "Sistema";
    }

    function actionFor(binding, description) {
        if (description)
            return description.includes(":")
                ? description.slice(description.indexOf(":") + 1).trim()
                : description;

        const dispatcher = (binding.dispatcher ?? "").toString().toLowerCase();
        const arg = (binding.arg ?? "").toString();
        const ipcAction = arg.match(/(?:qs|quickshell)\s+ipc\s+call\s+shell\s+([\w]+)/i);
        if (ipcAction) {
            const labels = {
                toggleLauncher: "Abrir/fechar launcher",
                toggleLogout: "Abrir/fechar menu de sessão",
                toggleClipboardHistory: "Abrir/fechar histórico da área de transferência",
                screenshotRegion: "Capturar uma região da tela",
                screenshotWindow: "Capturar uma janela",
                toggleWallpaper: "Abrir/fechar seletor de wallpaper",
                toggleWallhaven: "Abrir/fechar Wallhaven",
                toggleNotificationCenter: "Abrir/fechar notificações",
                increaseVolume: "Aumentar volume",
                decreaseVolume: "Diminuir volume",
                toggleMute: "Alternar mute do áudio",
                increaseBrightness: "Aumentar brilho",
                decreaseBrightness: "Diminuir brilho"
            };
            return labels[ipcAction[1]] ?? `Ação QuickShell: ${ipcAction[1]}`;
        }

        if (dispatcher === "exec") {
            const command = arg.replace(/^\s*(?:exec|exec-once)\s*/, "").trim();
            if (/^kitty(?:\s|$)/i.test(command)) return "Abrir terminal";
            if (/^dolphin(?:\s|$)/i.test(command)) return "Abrir gerenciador de arquivos";
            if (/^firefox(?:\s|$)/i.test(command)) return "Abrir navegador";
            if (/playerctl\s+next/i.test(command)) return "Próxima faixa";
            if (/playerctl\s+previous/i.test(command)) return "Faixa anterior";
            if (/playerctl\s+play-pause/i.test(command)) return "Reproduzir/pausar mídia";
            if (/playerctl\s+volume/i.test(command)) return "Ajustar volume da mídia";
            if (/wpctl\s+set-mute/i.test(command)) return "Alternar mute do microfone";
            if (/wpctl\s+set-volume/i.test(command)) return "Ajustar volume do sistema";
            if (/brightness/i.test(command)) return "Ajustar brilho";
            return `Executar: ${command}`;
        }

        const dispatcherLabels = {
            movefocus: "Focar janela",
            movewindow: "Mover janela",
            resizeactive: "Redimensionar janela",
            workspace: "Mudar para workspace",
            movetoworkspace: "Mover janela para workspace",
            fullscreen: "Alternar tela cheia",
            togglefloating: "Alternar janela flutuante",
            togglesplit: "Alternar divisão",
            killactive: "Fechar janela",
            closewindow: "Fechar janela",
            pseudo: "Alternar modo pseudo",
            exit: "Sair do Hyprland"
        };
        const label = dispatcherLabels[dispatcher] ?? dispatcher;
        return arg ? `${label}: ${arg}` : label || "Ação do compositor";
    }

    function formatBinding(binding) {
        const description = (binding.description ?? "").toString().trim();
        const modifiers = modifierNames(Number(binding.modmask ?? 0));
        const key = displayKey(binding);
        if (key)
            modifiers.push(key);
        return {
            shortcut: modifiers.join(" + ") || key,
            category: categoryFor(binding, description),
            action: actionFor(binding, description)
        };
    }

    function toggle(monitor) {
        if (active) {
            close();
            return;
        }

        // Keep the compositor window that had keyboard focus before the
        // layer-shell panel takes it. Reopening during the short close delay
        // should keep the original target instead of remembering the panel.
        if (!restoreFocusTimer.running)
            previousToplevel = Hyprland.activeToplevel;
        restoreFocusTimer.stop();
        targetMonitor = monitor ?? Hyprland.focusedMonitor;
        searchText = "";
        loadError = "";
        bindings = [];
        loading = true;
        active = true;
        if (!bindingsProcess.running)
            bindingsProcess.running = true;
    }

    function close() {
        if (!active)
            return;
        active = false;
        targetMonitor = null;
        searchText = "";
        bindings = [];
        loading = false;
        restoreFocusTimer.restart();
    }

    function restorePreviousWindowFocus() {
        const toplevel = previousToplevel;
        previousToplevel = null;
        if (!toplevel || active)
            return;
        toplevel.activate();
    }

    Timer {
        id: restoreFocusTimer
        interval: 80
        repeat: false
        onTriggered: root.restorePreviousWindowFocus()
    }

    Process {
        id: bindingsProcess
        command: ["hyprctl", "-j", "binds"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active)
                    return;
                root.loading = false;
                try {
                    const parsed = JSON.parse(text);
                    root.bindings = parsed.filter(binding => binding.key || binding.keycode);
                    if (root.bindings.length === 0)
                        root.loadError = "O Hyprland não retornou atalhos.";
                } catch (error) {
                    root.loadError = "Não foi possível ler os atalhos do Hyprland.";
                    console.warn("[KeybindCheatsheet] Could not parse hyprctl binds:", error);
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0 && root.active) {
                root.loadError = "Não foi possível consultar as binds do Hyprland.";
                console.warn("[KeybindCheatsheet] hyprctl binds failed with code", exitCode);
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Item {
                id: screenDelegate
                required property var modelData

                LazyLoader {
                    id: screenLoader
                    activeAsync: root.active
                        && Hyprland.monitorFor(screenDelegate.modelData) === root.targetMonitor

                    PanelWindow {
                        screen: screenDelegate.modelData
                        color: "transparent"
                        focusable: true
                        exclusionMode: ExclusionMode.Ignore
                        exclusiveZone: 0
                        WlrLayershell.layer: WlrLayer.Overlay
                        WlrLayershell.namespace: "quickshell:keybind-cheatsheet"
                        WlrLayershell.keyboardFocus: root.active
                            ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                        anchors {
                            top: true
                            bottom: true
                            left: true
                            right: true
                        }

                        Component.onCompleted: Qt.callLater(() => searchField.forceActiveFocus())

                        Widgets.FocusDismissBehavior {
                            window: screenLoader.item
                            dismissAction: () => root.close()
                        }

                        contentItem {
                            focus: root.active
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.close();
                                    event.accepted = true;
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.close()
                        }

                        Widgets.SurfaceCard {
                            id: card
                            anchors.centerIn: parent
                            width: Math.max(1, Math.min(parent.width - 32, 820))
                            height: Math.max(1, Math.min(parent.height - 32, 760))
                            z: 1
                            surfaceColor: Config.Theme.colBg
                            cornerRadius: Config.Theme.radiusPanel

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "Atalhos do Hyprland"
                                        color: Config.Theme.colFg
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: Config.Theme.fontSizeLarge
                                        font.bold: true
                                    }

                                    Text {
                                        text: `${root.filteredBindings.length} atalhos · Esc para fechar`
                                        color: Config.Theme.colTextSec
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: Config.Theme.fontSizeSmall
                                    }
                                }

                                Widgets.IconButton {
                                    iconName: "close"
                                    Accessible.name: "Fechar cheatsheet de atalhos"
                                    onClicked: root.close()
                                }
                            }

                            Widgets.ThemedTextField {
                                id: searchField
                                Layout.fillWidth: true
                                placeholderText: "Buscar atalho ou ação..."
                                horizontalTextPadding: 6
                                selectByMouse: true
                                activeFocusOnTab: true

                                background: Widgets.SurfaceCard {
                                    surfaceColor: Config.Theme.colSurface
                                    outlineOpacity: searchField.activeFocus ? 0.8 : 0.25
                                    cornerRadius: Config.Theme.radiusControl
                                }

                                onTextChanged: root.searchText = text
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.close();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Down
                                               && shortcutList.count > 0) {
                                        shortcutList.currentIndex = 0;
                                        shortcutList.forceActiveFocus();
                                        event.accepted = true;
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Config.Theme.radiusCard
                                color: Config.Theme.colPanel
                                clip: true

                                ListView {
                                    id: shortcutList
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    clip: true
                                    spacing: 2
                                    model: root.filteredBindings
                                    activeFocusOnTab: true
                                    keyNavigationEnabled: true
                                    currentIndex: -1

                                    delegate: Item {
                                        required property var modelData
                                        required property int index
                                        width: shortcutList.width
                                        readonly property bool categoryHeader: index === 0
                                            || root.filteredBindings[index - 1]?.category
                                                !== modelData.category
                                        height: 52 + (categoryHeader ? 30 : 0)

                                        Text {
                                            visible: parent.categoryHeader
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.leftMargin: 8
                                            text: modelData.category
                                            color: Config.Theme.colHighlight
                                            font.family: Config.Theme.fontFamily
                                            font.pixelSize: Config.Theme.fontSizeSmall
                                            font.bold: true
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 48
                                            radius: Config.Theme.radiusControl
                                            color: shortcutList.currentIndex === index
                                                ? Config.Theme.colHighlightContainer
                                                : rowMouse.containsMouse
                                                    ? Config.Theme.colSurface : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 12
                                                spacing: 12

                                                Text {
                                                    Layout.minimumWidth: 0
                                                    Layout.preferredWidth: Math.min(250, shortcutList.width * 0.42)
                                                    text: modelData.shortcut
                                                    color: shortcutList.currentIndex === index
                                                        ? Config.Theme.colOnHighlightContainer
                                                        : Config.Theme.colFg
                                                    font.family: Config.Theme.fontFamily
                                                    font.pixelSize: Config.Theme.fontSizeSmall
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.action
                                                    color: shortcutList.currentIndex === index
                                                        ? Config.Theme.colOnHighlightContainer
                                                        : Config.Theme.colTextSec
                                                    font.family: Config.Theme.fontFamily
                                                    font.pixelSize: Config.Theme.fontSizeSmall
                                                    elide: Text.ElideRight
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                            }

                                            MouseArea {
                                                id: rowMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onEntered: shortcutList.currentIndex = index
                                                onClicked: shortcutList.forceActiveFocus()
                                            }
                                        }
                                    }

                                    ScrollBar.vertical: Widgets.ThemeScrollBar { policy: ScrollBar.AsNeeded }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    visible: root.loadError !== ""
                                        || root.loading
                                        || (root.bindings.length > 0
                                            && root.filteredBindings.length === 0)

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.loadError || (root.loading
                                            ? "Carregando atalhos..."
                                            : "Nenhum atalho corresponde à busca.")
                                        color: Config.Theme.colTextSec
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: Config.Theme.fontSize
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}
