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
    property string searchText: ""
    property var wallpapers: []
    property int selectedIndex: 0
    property int currentPage: 1
    property int lastPage: 1
    property string statusMessage: "Type something to search Wallhaven."
    property bool requestRunning: false
    property int requestGeneration: 0
    property int activeRequestGeneration: 0
    property string activeSearchQuery: ""
    property int activeSearchPage: 1
    property string minimumResolution: ""
    property string searchResolution: ""
    property string activeSearchResolution: ""
    property bool resolutionFallbackUsed: false
    property bool resolutionDetectionFailed: false
    property var pageCache: ({})
    property var prefetchQueue: []
    property bool prefetchRunning: false
    property string activePrefetchQuery: ""
    property int activePrefetchPage: 0
    property string activePrefetchResolution: ""
    property int activePrefetchGeneration: 0
    property int monitorResolutionGeneration: 0
    property bool openPrepared: false
    readonly property bool requestedVisible: Services.WindowControl.wallhavenVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.wallhavenMonitor

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

    function closePicker() {
        Services.WindowControl.wallhavenVisible = false;
        Services.WindowControl.wallhavenMonitor = null;
    }

    function preparePicker() {
        if (!requestedVisible || openPrepared)
            return;
        openPrepared = true;
        requestGeneration++;
        searchText = "";
        wallpapers = [];
        selectedIndex = 0;
        currentPage = 1;
        lastPage = 1;
        minimumResolution = "";
        searchResolution = "";
        resolutionFallbackUsed = false;
        resolutionDetectionFailed = false;
        pageCache = ({});
        prefetchQueue = [];
        monitorResolutionGeneration = requestGeneration;
        statusMessage = "Reading monitor resolutions…";
        if (!monitorProcess.running)
            monitorProcess.running = true;
        Qt.callLater(() => {
            if (root.requestedVisible)
                resultsGrid.forceActiveFocus();
        });
    }

    function finishClose() {
        openPrepared = false;
        searchText = "";
        wallpapers = [];
        selectedIndex = 0;
        pageCache = ({});
        prefetchQueue = [];
    }

    function readMonitorResolution(output) {
        let monitors;
        try {
            monitors = JSON.parse(String(output || ""));
        } catch (error) {
            console.warn("Could not parse Hyprland resolutions:", error);
            return "";
        }

        if (!Array.isArray(monitors))
            return "";

        let largest = null;
        for (const monitor of monitors) {
            if (!monitor || monitor.disabled)
                continue;

            let width = Number(monitor.width);
            let height = Number(monitor.height);
            if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0)
                continue;

            // Hyprland transform values 1, 3, 5 and 7 rotate the output by 90°/270°.
            const transform = Number(monitor.transform);
            if (Number.isFinite(transform) && transform % 2 === 1) {
                const previousWidth = width;
                width = height;
                height = previousWidth;
            }

            const candidate = { width: width, height: height, area: width * height };
            if (!largest || candidate.area > largest.area)
                largest = candidate;
        }

        return largest ? largest.width + "x" + largest.height : "";
    }

    function startSearch(page, resolution, statusOverride) {
        const query = normalizedQuery();
        statusMessage = statusOverride || (query ? "Searching Wallhaven…" : "Loading the Toplist…");
        requestRunning = true;
        activeRequestGeneration = requestGeneration;
        activeSearchQuery = query;
        activeSearchPage = page;
        activeSearchResolution = resolution;

        searchProcess.exec(["curl", "-fsSL", "--connect-timeout", "12", "--max-time", "35",
                            requestUrl(query, page, resolution)]);
    }

    function search(page) {
        if (requestRunning || Services.WallpaperManager.busy)
            return;
        currentPage = Math.max(1, Math.min(page, lastPage));
        selectedIndex = 0;
        const query = normalizedQuery();
        const resolution = searchResolution;
        const cachedPage = pageCache[cacheKey(query, currentPage, resolution)];
        if (cachedPage) {
            showPage(cachedPage);
            queueNeighborPages(currentPage);
            resultsGrid.forceActiveFocus();
            return;
        }

        startSearch(currentPage, resolution);
        resultsGrid.forceActiveFocus();
    }

    function requestUrl(query, page, resolution) {
        return "https://wallhaven.cc/api/v1/search?categories=111&purity=100&sorting=toplist&topRange=1M&page="
            + page + (query ? "&q=" + encodeURIComponent(query) : "")
            + (resolution ? "&atleast=" + encodeURIComponent(resolution) : "");
    }

    function cacheKey(query, page, resolution) {
        return query + "::" + page + "::" + (resolution || "all-resolutions");
    }

    function normalizedQuery() {
        return String(searchText || "").replace(/^\s+|\s+$/g, "");
    }

    function retryWithoutResolution(message) {
        if (!activeSearchResolution)
            return false;

        resolutionFallbackUsed = true;
        searchResolution = "";
        startSearch(activeSearchPage, "", message);
        return true;
    }

    function storePage(query, page, data, responseLastPage, resolution) {
        const key = cacheKey(query, page, resolution);
        const nextCache = {};
        const keys = Object.keys(pageCache).filter(k => k !== key);
        const maxPages = 8;
        const startIndex = keys.length >= maxPages ? (keys.length - maxPages + 1) : 0;
        for (let i = startIndex; i < keys.length; i++)
            nextCache[keys[i]] = pageCache[keys[i]];

        nextCache[key] = {
            data: data,
            currentPage: page,
            lastPage: responseLastPage,
            minimumResolution: resolution
        };
        pageCache = nextCache;
    }

    function showPage(cachedPage) {
        wallpapers = cachedPage.data;
        currentPage = cachedPage.currentPage;
        lastPage = cachedPage.lastPage;
        selectedIndex = 0;
        const resolutionNote = cachedPage.minimumResolution
            ? " · minimum " + cachedPage.minimumResolution
            : (root.resolutionFallbackUsed
                ? " · unfiltered (no results for ≥ " + root.minimumResolution + ")"
                : (root.resolutionDetectionFailed ? " · resolution unavailable" : ""));
        statusMessage = wallpapers.length
            ? wallpapers.length + " results" + resolutionNote + " · page " + currentPage + " of " + lastPage
            : "No wallpapers found. Try other terms.";
    }

    function queueNeighborPages(centerPage) {
        if (!visible || !lastPage)
            return;

        const query = normalizedQuery();
        const resolution = searchResolution;
        const candidates = [];
        for (let distance = 1; distance <= 2; distance++) {
            const ahead = centerPage + distance;
            const behind = centerPage - distance;
            if (ahead <= lastPage)
                candidates.push(ahead);
            if (behind >= 1)
                candidates.push(behind);
        }
        const missingPages = [];
        for (let i = 0; i < candidates.length; i++) {
            if (!pageCache[cacheKey(query, candidates[i], resolution)])
                missingPages.push(candidates[i]);
        }
        prefetchQueue = missingPages;
        runNextPrefetch();
    }

    function runNextPrefetch() {
        if (prefetchRunning || !prefetchQueue.length || !visible)
            return;

        const query = normalizedQuery();
        let page = 0;
        while (prefetchQueue.length && !page) {
            page = prefetchQueue[0];
            prefetchQueue.splice(0, 1);
        }
        if (!page)
            return;

        activePrefetchQuery = query;
        activePrefetchPage = page;
        const resolution = searchResolution;
        activePrefetchResolution = resolution;
        activePrefetchGeneration = requestGeneration;
        prefetchRunning = true;
        prefetchProcess.exec(["curl", "-fsSL", "--connect-timeout", "12", "--max-time", "35",
                              requestUrl(query, page, resolution)]);
    }

    function selectIndex(index) {
        const count = wallpapers.length;
        if (!count) {
            selectedIndex = 0;
            resultsGrid.currentIndex = -1;
            return;
        }
        selectedIndex = Math.max(0, Math.min(index, count - 1));
        resultsGrid.currentIndex = selectedIndex;
    }

    function applySelected() {
        const item = wallpapers[selectedIndex];
        if (item && !Services.WallpaperManager.busy)
            Services.WallpaperManager.downloadAndApply(item);
    }

    function handleSearchKey(event) {
        if (event.key === Qt.Key_Escape) {
            closePicker();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down && wallpapers.length) {
            selectIndex(0);
            resultsGrid.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            search(1);
            event.accepted = true;
        }
    }

    function handleGridKey(event) {
        const columns = Math.max(1, Math.floor(resultsGrid.width / 230));
        if (event.key === Qt.Key_Escape) {
            closePicker();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_Left
                   && currentPage > 1) {
            search(currentPage - 1);
            event.accepted = true;
        } else if ((event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_Right
                   && currentPage < lastPage) {
            search(currentPage + 1);
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
            applySelected();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            searchText = searchText.slice(0, -1);
            pageCache = ({});
            prefetchQueue = [];
            Qt.callLater(() => searchField.forceActiveFocus());
            event.accepted = true;
        } else if (event.text && String(event.text).charAt(0) !== "\u001b") {
            searchText += event.text;
            pageCache = ({});
            prefetchQueue = [];
            Qt.callLater(() => searchField.forceActiveFocus());
            event.accepted = true;
        }
    }

    Component.onCompleted: preparePicker()
    onRequestedVisibleChanged: {
        if (requestedVisible) {
            preparePicker();
        } else {
            requestGeneration++;
            openPrepared = false;
        }
    }
    onVisibleChanged: if (!visible) finishClose()

    Process {
        id: monitorProcess
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector { id: monitorOutput }
        onExited: (exitCode, exitStatus) => {
            if (!root.requestedVisible
                    || root.monitorResolutionGeneration !== root.requestGeneration)
                return;

            const resolution = exitCode === 0
                ? root.readMonitorResolution(monitorOutput.text)
                : "";
            root.minimumResolution = resolution;
            root.searchResolution = resolution;
            root.resolutionDetectionFailed = !resolution;
            if (resolution) {
                root.statusMessage = "Loading wallpapers with minimum resolution " + resolution + "…";
            } else {
                root.statusMessage = "Could not read the resolution; loading without a filter…";
                console.warn("Could not get resolutions from `hyprctl -j monitors`; using unfiltered search.");
            }
            root.search(1);
        }
    }

    Process {
        id: searchProcess
        stdout: StdioCollector { id: searchOutput }
        onExited: (exitCode, exitStatus) => {
            root.requestRunning = false;
            if (root.activeRequestGeneration !== root.requestGeneration) {
                if (root.requestedVisible)
                    Qt.callLater(() => root.search(1));
                return;
            }
            if (root.activeSearchQuery !== root.normalizedQuery()) {
                Qt.callLater(() => root.search(1));
                return;
            }
            if (exitCode !== 0) {
                root.wallpapers = [];
                root.statusMessage = "Could not reach Wallhaven. Check your connection and try again.";
                return;
            }
            let response;
            try {
                response = JSON.parse(String(searchOutput.text || ""));
            } catch (error) {
                console.warn("Wallhaven returned non-JSON content:", error);
                root.wallpapers = [];
                root.statusMessage = "Wallhaven responded with an invalid format: " + error;
                return;
            }
            if (!response || !response.data || typeof response.data.length !== "number" || !response.meta) {
                const detail = (response && (response.error || response.message)) || "missing data/meta fields";
                if (root.retryWithoutResolution("The filtered search failed; retrying without a resolution filter…"))
                    return;
                console.warn("Unexpected Wallhaven API response:", detail);
                root.wallpapers = [];
                root.statusMessage = "Unexpected response from Wallhaven: " + detail;
                return;
            }

            try {
                const data = response.data;
                if (!data.length && root.retryWithoutResolution(
                        "No results at this resolution; retrying without a filter…"))
                    return;

                const page = Number(response.meta.current_page || root.activeSearchPage);
                const lastPage = Number(response.meta.last_page || 1);
                root.storePage(root.activeSearchQuery, page, data, lastPage, root.activeSearchResolution);
                root.showPage(root.pageCache[root.cacheKey(
                    root.activeSearchQuery, page, root.activeSearchResolution)]);
                root.queueNeighborPages(page);
                root.selectIndex(0);
                resultsGrid.forceActiveFocus();
            } catch (error) {
                console.warn("Failed processing Wallhaven results:", error);
                root.wallpapers = [];
                root.statusMessage = "Failed to process Wallhaven results: " + error;
            }
        }
    }

    Process {
        id: prefetchProcess
        stdout: StdioCollector { id: prefetchOutput }
        onExited: (exitCode, exitStatus) => {
            root.prefetchRunning = false;
            if (root.activePrefetchGeneration === root.requestGeneration
                    && root.activePrefetchQuery === root.normalizedQuery()
                    && root.activePrefetchResolution === root.searchResolution
                    && exitCode === 0) {
                try {
                    const response = JSON.parse(String(prefetchOutput.text || ""));
                    const data = response.data || [];
                    const lastPage = Number((response.meta && response.meta.last_page) || root.lastPage);
                    root.storePage(root.activePrefetchQuery, root.activePrefetchPage,
                                   data, lastPage, root.activePrefetchResolution);
                    root.lastPage = lastPage;
                    root.queueNeighborPages(root.currentPage);
                } catch (error) {
                    // Prefetching is opportunistic; a failure does not interrupt browsing.
                }
            }
            root.runNextPrefetch();
        }
    }

    Connections {
        target: Services.WallpaperManager
        function onStatusChanged() {
            root.statusMessage = Services.WallpaperManager.status;
        }
        function onOperationFinished(path, success) {
            if (success)
                root.closePicker();
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
            width: Math.max(1, Math.min(1120, parent.width - 48))
            height: Math.max(1, Math.min(790, parent.height - 96))
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: Math.max(0, Math.min(64, (parent.height - panel.height) / 2))
            }
            radius: 26
            color: Config.Theme.colBg
            border.width: 1
            border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                  Config.Theme.colTextSec.b, 0.28)
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
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: 44
                    spacing: 10
                    Text {
                        text: "travel_explore"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 25
                        color: Config.Theme.colHighlight
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Wallhaven"
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeLarge
                            font.bold: true
                        }
                        Text {
                            text: "Search and download to the configured wallpaper folder"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Widgets.ThemedTextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        text: root.searchText
                        onTextChanged: {
                            if (root.searchText !== text) {
                                root.searchText = text;
                                root.pageCache = ({});
                                root.prefetchQueue = [];
                                root.currentPage = 1;
                                root.lastPage = 1;
                            }
                        }
                        placeholderText: "Search wallpapers (e.g. mountains, cyberpunk)…"
                        enabled: !Services.WallpaperManager.busy
                        fieldRadius: 11
                        Keys.onPressed: event => root.handleSearchKey(event)
                    }
                    Widgets.ActionButton {
                        label: "Search"
                        iconName: "search"
                        emphasized: true
                        enabled: !root.requestRunning && !Services.WallpaperManager.busy
                        onClicked: root.search(1)
                    }
                }

                GridView {
                    id: resultsGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.wallpapers
                    cellWidth: width / Math.max(1, Math.floor(width / 230))
                    cellHeight: cellWidth * 0.72
                    currentIndex: root.selectedIndex
                    focus: root.requestedVisible
                    Keys.onPressed: event => root.handleGridKey(event)
                    ScrollBar.vertical: Widgets.ThemeScrollBar { }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: resultsGrid.cellWidth - 10
                        height: resultsGrid.cellHeight - 10
                        radius: 10
                        clip: true
                        color: Config.Theme.colOsdBg

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Config.Theme.colOsdBg
                            Image {
                                anchors.fill: parent
                                source: (modelData.thumbs && modelData.thumbs.large) || ""
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
                                height: 42
                                color: "#bb000000"
                                Column {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 8
                                    spacing: 2
                                    Text {
                                        width: parent.width
                                        text: modelData.id + " · " + modelData.resolution
                                        color: "white"
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: Config.Theme.fontSizeSmall
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: modelData.category + " · " + modelData.file_type
                                        color: "#dddddd"
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: Config.Theme.fontSizeSmall - 1
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            z: 2
                            radius: 10
                            color: "transparent"
                            border.width: index === root.selectedIndex ? 3 : 0
                            border.color: Config.Theme.colHighlight
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !Services.WallpaperManager.busy
                            onEntered: root.selectIndex(index)
                            onClicked: {
                                root.selectIndex(index);
                                root.applySelected();
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        text: root.statusMessage
                        color: String(root.statusMessage).indexOf("Could not") === 0
                            || String(root.statusMessage).indexOf("Unexpected") === 0
                            || String(root.statusMessage).indexOf("Wallhaven responded") === 0
                            || String(root.statusMessage).indexOf("Failed") === 0
                            ? Config.Theme.colRed : Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: root.wallpapers.length > 0
                        text: root.currentPage + " / " + root.lastPage
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Type to search · Enter search/apply · ← → ↑ ↓ choose · Shift+←/→ pages · ESC close"
                    color: Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }

            Text {
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 22
                    rightMargin: 24
                }
                text: "ESC"
                color: Config.Theme.colTextSec
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
            }
        }
    }

}
