import ".." as Config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../services" as Services

PanelWindow {
    id: root

    required property var targetScreen
    readonly property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string wallpaperDirectory: defaultDirectory
    property var wallpapers: []
    property string searchText: ""
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
        wallpapers = [];
    }

    function selectIndex(index) {
        const count = filteredWallpapers.length;
        if (count === 0) {
            selectedIndex = 0;
            wallpaperGrid.currentIndex = -1;
            return;
        }
        selectedIndex = Math.max(0, Math.min(index, count - 1));
        wallpaperGrid.currentIndex = selectedIndex;
    }

    function handleSearchKey(event) {
        if (event.key === Qt.Key_Escape) {
            closePicker();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            selectIndex(selectedIndex);
            wallpaperGrid.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const path = filteredWallpapers[selectedIndex];
            if (path)
                applyWallpaper(path);
            event.accepted = true;
        }
    }

    function handleGridKey(event) {
        // Let the focused search field handle text entry and cursor editing.
        if (searchField.activeFocus)
            return;

        const columns = Math.max(1, Math.floor(wallpaperGrid.width / 220));
        if (event.key === Qt.Key_Escape) {
            closePicker();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            selectIndex(selectedIndex - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            selectIndex(selectedIndex + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            selectIndex(selectedIndex - columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            selectIndex(selectedIndex + columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const path = filteredWallpapers[selectedIndex];
            if (path)
                applyWallpaper(path);
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            searchText = searchText.slice(0, -1);
            selectIndex(0);
            Qt.callLater(() => searchField.forceActiveFocus());
            event.accepted = true;
        } else if (event.text && !event.text.startsWith("\u001b")) {
            searchText += event.text;
            selectIndex(0);
            Qt.callLater(() => searchField.forceActiveFocus());
            event.accepted = true;
        }
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
        if (Services.WallpaperManager.busy)
            return;
        Services.WallpaperManager.apply(path);
    }

    function showError(message) {
        statusMessage = message;
    }

    component ActionButton: Rectangle {
        id: action

        required property string label
        required property string iconName
        property bool emphasized: false
        signal clicked()

        implicitWidth: actionRow.implicitWidth + 24
        implicitHeight: 38
        radius: 9
        color: actionMouse.containsMouse
            ? Config.Theme.colWlogoutButtonHover
            : (emphasized
                ? Config.Theme.colWlogoutButton
                : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                          Config.Theme.colTextSec.b, 0.10))
        border.width: 1
        border.color: actionMouse.containsMouse || emphasized
            ? Config.Theme.colHighlight
            : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                      Config.Theme.colTextSec.b, 0.18)

        RowLayout {
            id: actionRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: action.iconName
                color: action.emphasized ? Config.Theme.colHighlight : Config.Theme.colFg
                font.family: "Material Symbols Rounded"
                font.pixelSize: 17
            }
            Text {
                text: action.label
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                font.bold: action.emphasized
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    onVisibleChanged: {
        if (visible) {
            scanDirectory(wallpaperDirectory);
            Qt.callLater(() => wallpaperGrid.forceActiveFocus());
        } else {
            searchText = "";
            wallpapers = [];
        }
    }

    contentItem {
        focus: root.visible
        Keys.onPressed: event => root.handleGridKey(event)
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

    Connections {
        target: Services.WallpaperManager
        function onStatusChanged() {
            root.statusMessage = Services.WallpaperManager.status;
        }
        function onOperationFinished(path, success) {
            if (success)
                root.currentWallpaper = path;
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
                    ActionButton {
                        label: "Carregar"
                        iconName: "folder_open"
                        emphasized: true
                        onClicked: root.scanDirectory(directoryField.text)
                    }
                    ActionButton {
                        visible: !root.folderExists && directoryField.text.trim() === root.defaultDirectory
                        label: "Criar pasta padrão"
                        iconName: "create_new_folder"
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
                    Keys.onPressed: event => root.handleSearchKey(event)
                }

                GridView {
                    id: wallpaperGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.filteredWallpapers
                    cellWidth: width / Math.max(1, Math.floor(width / 220))
                    cellHeight: cellWidth * 0.76
                    currentIndex: root.selectedIndex
                    Keys.onPressed: event => root.handleGridKey(event)
                    ScrollBar.vertical: ScrollBar { }

                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        width: wallpaperGrid.cellWidth - 10
                        height: wallpaperGrid.cellHeight - 10
                        radius: 10
                        clip: true
                        color: Config.Theme.colOsdBg

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Config.Theme.colOsdBg

                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData
                                sourceSize.width: 480
                                sourceSize.height: 360
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
                        }

                        Rectangle {
                            anchors.fill: parent
                            z: 2
                            radius: 10
                            color: "transparent"
                            border.width: index === root.selectedIndex
                                ? 3 : (modelData === root.currentWallpaper ? 1 : 0)
                            border.color: index === root.selectedIndex
                                ? Config.Theme.colHighlight : Config.Theme.colTextSec
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
                        text: "↓ lista     ← → ↑ ↓ escolher     ↵ aplicar     ESC fechar"
                        color: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                    }
                }
            }
        }
    }
}
