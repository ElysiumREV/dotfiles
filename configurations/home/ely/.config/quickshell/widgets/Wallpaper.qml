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
import "../widgets" as Widgets

PanelWindow {
    id: root

    required property var targetScreen
    property bool keepVisible: false
    readonly property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string wallpaperDirectory: Services.WallpaperManager.wallpaperDirectory
    property var wallpapers: []
    property string searchText: ""
    property string currentWallpaper: ""
    property string statusMessage: ""
    property bool folderExists: true
    property int selectedIndex: 0
    property bool openPrepared: false
    readonly property bool requestedVisible: Services.WindowControl.wallpaperVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.wallpaperMonitor

    color: "transparent"
    screen: targetScreen
    visible: requestedVisible || keepVisible
    focusable: requestedVisible
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: requestedVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusDismissBehavior {
        window: root
        active: root.requestedVisible
        dismissAction: () => root.closePicker()
    }

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

    function closePicker() {
        Services.WindowControl.wallpaperVisible = false;
        Services.WindowControl.wallpaperMonitor = null;
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
            statusMessage = "Enter the wallpaper folder path.";
            return;
        }

        wallpaperDirectory = cleanPath;
        wallpapers = [];
        statusMessage = "Searching for wallpapers…";
        scanProcess.exec([
            "find", cleanPath, "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o",
            "-iname", "*.jpeg", "-o", "-iname", "*.webp", "-o",
            "-iname", "*.avif", "-o", "-iname", "*.bmp", ")", "-print"
        ]);
    }

    function createDefaultDirectory() {
        statusMessage = "Creating " + defaultDirectory + "…";
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

    function preparePicker() {
        if (!requestedVisible || openPrepared)
            return;
        openPrepared = true;
        scanDirectory(wallpaperDirectory);
        Qt.callLater(() => {
            if (root.requestedVisible)
                wallpaperGrid.forceActiveFocus();
        });
    }

    Component.onCompleted: preparePicker()
    onRequestedVisibleChanged: {
        if (requestedVisible)
            preparePicker();
        else
            openPrepared = false;
    }
    onVisibleChanged: {
        if (!visible) {
            searchText = "";
            wallpapers = [];
        }
    }

    contentItem {
        focus: root.requestedVisible
        Keys.onPressed: event => root.handleGridKey(event)
    }

    Process {
        id: scanProcess
        stdout: StdioCollector { id: scanOutput }
        onExited: (exitCode, exitStatus) => {
            root.folderExists = exitCode === 0;
            if (exitCode !== 0) {
                root.wallpapers = [];
                root.statusMessage = "Could not find that folder. Enter another path or create the default folder.";
                return;
            }

            root.wallpapers = scanOutput.text.split("\n").filter(path => path !== "")
                .sort((a, b) => a.split("/").pop().localeCompare(b.split("/").pop()));
            Config.Preferences.wallpaper.directory = root.wallpaperDirectory;
            root.statusMessage = root.wallpapers.length
                ? root.wallpapers.length + " wallpapers found"
                : "The folder exists, but no compatible images were found.";
        }
    }

    Process {
        id: createDirectoryProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.scanDirectory(root.defaultDirectory);
            else
                root.showError("Could not create the default folder.");
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
        enabled: root.requestedVisible
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: root.requestedVisible
            onClicked: root.closePicker()
        }

        Rectangle {
            id: panel
            width: Math.max(1, Math.min(980, parent.width - 48))
            height: Math.max(1, Math.min(720, parent.height - 96))
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: Math.max(0, Math.min(64, (parent.height - panel.height) / 2))
            }
            radius: 26
            color: Config.Theme.colBg
            border.width: 1
            border.color: Config.Theme.alpha(Config.Theme.colTextSec, 0.28)
            opacity: root.requestedVisible ? 1 : 0
            scale: root.requestedVisible ? 1 : 0.96

            Behavior on opacity {
                NumberAnimation { duration: Config.Theme.motionEnter; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: Config.Theme.motionEnter; easing.type: Easing.OutBack }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.requestedVisible
                onClicked: mouse => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: Config.Theme.spaceMd
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "wallpaper"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeXl
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
                    spacing: Config.Theme.spaceSm
                    Widgets.ThemedTextField {
                        id: directoryField
                        Layout.fillWidth: true
                        text: root.wallpaperDirectory
                        onTextChanged: root.wallpaperDirectory = text
                        placeholderText: "Wallpaper folder path"
                        fieldRadius: 9
                        font.pixelSize: Config.Theme.fontSizeSmall
                    }
                    Widgets.ActionButton {
                        label: "Load"
                        iconName: "folder_open"
                        emphasized: true
                        onClicked: root.scanDirectory(directoryField.text)
                    }
                    Widgets.ActionButton {
                        visible: !root.folderExists && directoryField.text.trim() === root.defaultDirectory
                        label: "Create default folder"
                        iconName: "create_new_folder"
                        onClicked: root.createDefaultDirectory()
                    }
                }

                Widgets.ThemedTextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    placeholderText: "Filter wallpapers by name…"
                    text: root.searchText
                    onTextChanged: {
                        root.searchText = text;
                        root.selectedIndex = 0;
                    }
                    fieldRadius: 11
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
                    ScrollBar.vertical: Widgets.ThemeScrollBar { }

                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        width: wallpaperGrid.cellWidth - 10
                        height: wallpaperGrid.cellHeight - 10
                        radius: Config.Theme.radiusCard
                        clip: true
                        color: Config.Theme.colOsdBg

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: Config.Theme.radiusCard
                            color: Config.Theme.colOsdBg

                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData
                                sourceSize.width: 320
                                sourceSize.height: 240
                                asynchronous: true
                                cache: false
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
                                    anchors.rightMargin: Config.Theme.spaceSm
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
                            radius: Config.Theme.radiusCard
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
                        color: root.statusMessage.startsWith("Failed") || root.statusMessage.startsWith("Could not")
                            ? Config.Theme.colRed : Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "↓ list     ← → ↑ ↓ choose     ↵ apply     ESC close"
                        color: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                    }
                }
            }
        }
    }
}
