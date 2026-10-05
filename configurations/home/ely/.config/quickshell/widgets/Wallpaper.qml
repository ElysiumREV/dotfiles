import ".." as Config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../services" as Services

PanelWindow {
    id: root

    required property var targetScreen
    readonly property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string wallpaperDirectory: defaultDirectory
    property var wallpapers: []
    property string searchText: ""
    property string pendingWallpaper: ""
    property string currentWallpaper: ""
    property string statusMessage: ""
    property bool folderExists: true
    property int selectedIndex: 0

    color: "transparent"
    screen: targetScreen
    visible: Services.WindowControl.wallpaperVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.wallpaperMonitor
    focusable: visible
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property var filteredWallpapers: {
        const query = searchText.trim().toLocaleLowerCase();
        if (!query)
            return wallpapers;
        return wallpapers.filter(path => path.split("/").pop().toLocaleLowerCase().includes(query));
    }

    function openPicker() {
        searchText = "";
        selectedIndex = 0;
        statusMessage = "";
        Services.WindowControl.openWallpaper(Hyprland.monitorFor(targetScreen));
    }

    function closePicker() {
        Services.WindowControl.wallpaperVisible = false;
        Services.WindowControl.wallpaperMonitor = null;
    }

    function scanDirectory(path) {
        const cleanPath = (path ?? "").trim();
        if (cleanPath === "") {
            folderExists = false;
            wallpapers = [];
            statusMessage = "Informe o caminho da pasta de wallpapers.";
            return;
        }

        wallpaperDirectory = cleanPath;
        wallpapers = [];
        statusMessage = "Procurando wallpapers…";
        scanProcess.exec([
            "find", cleanPath, "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o",
            "-iname", "*.jpeg", "-o", "-iname", "*.webp", "-o",
            "-iname", "*.avif", "-o", "-iname", "*.bmp", ")", "-print"
        ]);
    }

    function createDefaultDirectory() {
        statusMessage = "Criando " + defaultDirectory + "…";
        createDirectoryProcess.exec(["mkdir", "-p", defaultDirectory]);
    }

    function applyWallpaper(path) {
        pendingWallpaper = path;
        statusMessage = "Aplicando wallpaper…";
        wallpaperProcess.exec([
            "sh", "-c",
            "if command -v swww >/dev/null 2>&1; then exec swww img \"$1\"; else exec awww img \"$1\"; fi",
            "wallpaper-switch", path
        ]);
    }

    function showError(message) {
        statusMessage = message;
    }

    onVisibleChanged: {
        if (visible) {
            scanDirectory(wallpaperDirectory);
            Qt.callLater(() => searchField.forceActiveFocus());
        } else {
            searchText = "";
        }
    }

    Process {
        id: scanProcess
        stdout: StdioCollector { id: scanOutput }
        onExited: (exitCode, exitStatus) => {
            root.folderExists = exitCode === 0;
            if (exitCode !== 0) {
                root.wallpapers = [];
                root.statusMessage = "Não encontrei essa pasta. Informe outro caminho ou crie a pasta padrão.";
                return;
            }

            root.wallpapers = scanOutput.text.split("\n").filter(path => path !== "")
                .sort((a, b) => a.split("/").pop().localeCompare(b.split("/").pop()));
            root.statusMessage = root.wallpapers.length
                ? root.wallpapers.length + " wallpapers encontrados"
                : "A pasta existe, mas não encontrei imagens compatíveis.";
        }
    }

    Process {
        id: createDirectoryProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.scanDirectory(root.defaultDirectory);
            else
                root.showError("Não consegui criar a pasta padrão.");
        }
    }

    Process {
        id: wallpaperProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.showError("Falha ao trocar o wallpaper. Confira se o daemon swww/awww está ativo.");
                return;
            }
            currentLinkProcess.exec([
                "sh", "-c",
                "mkdir -p \"$2\" && ln -sfn \"$1\" \"$2/.current-wallpaper.png\"",
                "wallpaper-link", root.pendingWallpaper, root.defaultDirectory
            ]);
        }
    }

    Process {
        id: currentLinkProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.showError("Wallpaper trocado, mas não consegui atualizar o link usado pelo Hyprlock.");
                return;
            }
            matugenProcess.exec([
                "bash", Quickshell.env("HOME") + "/.config/scripts/updateWall.sh"
            ]);
        }
    }

    Process {
        id: matugenProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.currentWallpaper = root.pendingWallpaper;
                root.statusMessage = "Wallpaper e paleta atualizados.";
            } else {
                root.currentWallpaper = root.pendingWallpaper;
                root.statusMessage = "Wallpaper trocado, mas a geração de cores pelo Matugen falhou.";
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.closePicker()
        }

        Rectangle {
            id: panel
            width: Math.min(980, parent.width - 48)
            height: Math.min(720, parent.height - 48)
            anchors.centerIn: parent
            radius: 18
            color: Config.Theme.colBg
            border.width: 1
            border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                  Config.Theme.colTextSec.b, 0.28)

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "wallpaper"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 25
                        color: Config.Theme.colHighlight
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Wallpaper"
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeLarge
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.currentWallpaper ? root.currentWallpaper.split("/").pop() : root.wallpaperDirectory
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            elide: Text.ElideMiddle
                        }
                    }
                    Text {
                        text: "ESC"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    TextField {
                        id: directoryField
                        Layout.fillWidth: true
                        text: root.wallpaperDirectory
                        onTextChanged: root.wallpaperDirectory = text
                        placeholderText: "Caminho da pasta de wallpapers"
                        color: Config.Theme.colFg
                        placeholderTextColor: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        leftPadding: 12
                        background: Rectangle {
                            radius: 9
                            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                           Config.Theme.colTextSec.b, 0.10)
                        }
                    }
                    Button {
                        text: "Carregar"
                        onClicked: root.scanDirectory(directoryField.text)
                    }
                    Button {
                        visible: !root.folderExists && directoryField.text.trim() === root.defaultDirectory
                        text: "Criar pasta padrão"
                        onClicked: root.createDefaultDirectory()
                    }
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Filtrar wallpapers pelo nome…"
                    text: root.searchText
                    onTextChanged: {
                        root.searchText = text;
                        root.selectedIndex = 0;
                    }
                    color: Config.Theme.colFg
                    placeholderTextColor: Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSize
                    leftPadding: 12
                    background: Rectangle {
                        radius: 9
                        color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                       Config.Theme.colTextSec.b, 0.10)
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closePicker();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.selectedIndex = Math.min(root.selectedIndex + 1,
                                Math.max(0, root.filteredWallpapers.length - 1));
                            wallpaperGrid.currentIndex = root.selectedIndex;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                            wallpaperGrid.currentIndex = root.selectedIndex;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            const path = root.filteredWallpapers[root.selectedIndex];
                            if (path)
                                root.applyWallpaper(path);
                            event.accepted = true;
                        }
                    }
                }

                GridView {
                    id: wallpaperGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.filteredWallpapers
                    cellWidth: 220
                    cellHeight: 166
                    currentIndex: root.selectedIndex
                    ScrollBar.vertical: ScrollBar { }

                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        width: wallpaperGrid.cellWidth - 10
                        height: wallpaperGrid.cellHeight - 10
                        radius: 10
                        clip: true
                        color: Config.Theme.colOsdBg
                        border.width: modelData === root.currentWallpaper || index === root.selectedIndex ? 2 : 0
                        border.color: modelData === root.currentWallpaper ? Config.Theme.colHighlight : Config.Theme.colTextSec

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 36
                            color: "#bb000000"

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 8
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.split("/").pop()
                                color: "white"
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall
                                elide: Text.ElideMiddle
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                root.selectedIndex = index;
                                wallpaperGrid.currentIndex = index;
                            }
                            onClicked: root.applyWallpaper(modelData)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.statusMessage
                        color: root.statusMessage.startsWith("Falha") || root.statusMessage.startsWith("Não")
                            ? Config.Theme.colRed : Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "↑ ↓ navegar     ↵ aplicar     ESC fechar"
                        color: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                    }
                }
            }
        }
    }
}
