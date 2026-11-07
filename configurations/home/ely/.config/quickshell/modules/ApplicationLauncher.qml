import ".." as Config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../services" as Services
import "../widgets" as Widgets

PanelWindow {
    id: root

    required property var targetScreen
    property bool keepVisible: false
    property var indexedApplications: []
    property int selectedIndex: 0
    property string searchText: ""
    property string appliedSearchText: ""
    property bool keyboardNavigationActive: false
    readonly property bool requestedVisible: Services.WindowControl.launcherVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.launcherMonitor

    color: "transparent"
    screen: targetScreen
    visible: requestedVisible || keepVisible
    focusable: requestedVisible
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: requestedVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Widgets.FocusDismissBehavior {
        window: root
        active: root.requestedVisible
        dismissAction: () => root.closeLauncher()
    }

    function refreshApplications() {
        const entries = DesktopEntries.applications.values ?? [];
        const applications = entries.filter(entry => !entry.noDisplay && entry.name)
            .sort((a, b) => a.name.localeCompare(b.name));
        root.indexedApplications = applications.map(entry => ({
            entry: entry,
            id: entry.id || entry.name,
            name: root.normalizeSearchText(entry.name),
            genericName: root.normalizeSearchText(entry.genericName),
            comment: root.normalizeSearchText(entry.comment),
            keywords: (entry.keywords ?? []).map(keyword => root.normalizeSearchText(keyword))
        }));
    }

    function normalizeSearchText(value) {
        return (value ?? "").toString().normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase().trim();
    }

    function scoreField(field, token, weight) {
        if (!field)
            return 0;
        if (field === token)
            return weight + 120;
        if (field.startsWith(token))
            return weight + 100;
        if (field.split(/[\s._-]+/).some(word => word.startsWith(token)))
            return weight + 80;

        const position = field.indexOf(token);
        if (position >= 0)
            return weight + 60 - Math.min(position, 40);

        // Subsequence matching tolerates small gaps, e.g. "ffx" -> "Firefox".
        let cursor = 0;
        let gaps = 0;
        for (const character of token) {
            const next = field.indexOf(character, cursor);
            if (next < 0)
                return 0;
            gaps += next - cursor;
            cursor = next + 1;
        }
        return weight + Math.max(1, 30 - gaps);
    }

    readonly property var filteredApplications: {
        // Depend on usage changes only while usage-based ordering is enabled.
        const prioritizeUsage = Config.Preferences.launcher.prioritizeUsage;
        const usageRevision = prioritizeUsage ? Services.ApplicationUsage.revision : 0;
        const tokens = root.normalizeSearchText(root.appliedSearchText).split(/\s+/).filter(Boolean);
        const ranked = [];

        for (const item of root.indexedApplications) {
            let relevance = 0;
            let matches = true;

            for (const token of tokens) {
                let best = Math.max(
                    root.scoreField(item.name, token, 500),
                    root.scoreField(item.genericName, token, 300),
                    root.scoreField(item.comment, token, 150)
                );
                for (const keyword of item.keywords)
                    best = Math.max(best, root.scoreField(keyword, token, 250));
                if (best === 0) {
                    matches = false;
                    break;
                }
                relevance += best;
            }

            if (!matches)
                continue;
            ranked.push({
                entry: item.entry,
                name: item.name,
                relevance: relevance,
                usageCount: prioritizeUsage ? Services.ApplicationUsage.countFor(item.id) : 0,
                lastUsed: prioritizeUsage ? Services.ApplicationUsage.lastUsedFor(item.id) : 0
            });
        }

        ranked.sort((a, b) => {
            if (a.relevance !== b.relevance)
                return b.relevance - a.relevance;
            if (a.usageCount !== b.usageCount)
                return b.usageCount - a.usageCount;
            if (a.lastUsed !== b.lastUsed)
                return b.lastUsed - a.lastUsed;
            return a.name.localeCompare(b.name);
        });
        return ranked.map(item => item.entry);
    }

    function openLauncher() {
        refreshApplications();
        searchText = "";
        appliedSearchText = "";
        selectedIndex = 0;
        keyboardNavigationActive = true;
        Services.WindowControl.openLauncher(Hyprland.monitorFor(targetScreen));
    }

    function closeLauncher() {
        searchDebounce.stop();
        searchText = "";
        appliedSearchText = "";
        selectedIndex = 0;
        keyboardNavigationActive = false;
        Services.WindowControl.launcherVisible = false;
        Services.WindowControl.launcherMonitor = null;
    }

    function syncRequestedVisibility() {
        if (requestedVisible) {
            keyboardNavigationActive = true;
            Qt.callLater(() => {
                if (root.requestedVisible)
                    searchField.forceActiveFocus();
            });
        } else {
            searchDebounce.stop();
            searchText = "";
            appliedSearchText = "";
            selectedIndex = 0;
            keyboardNavigationActive = false;
        }
    }

    onRequestedVisibleChanged: syncRequestedVisibility()

    Timer {
        id: searchDebounce
        interval: 80
        repeat: false
        onTriggered: {
            root.appliedSearchText = root.searchText;
            root.selectedIndex = 0;
        }
    }

    function launchSelected() {
        const entry = filteredApplications[selectedIndex];
        if (!entry)
            return;
        Services.ApplicationUsage.record(entry.id || entry.name);
        closeLauncher();
        entry.execute();
    }

    Component.onCompleted: {
        refreshApplications();
        syncRequestedVisibility();
    }
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.refreshApplications(); }
    }

    Rectangle {
        anchors.fill: parent
        enabled: root.requestedVisible
        // The end-4 overview leaves the desktop visible and presents search as
        // a floating surface. A full-screen translucent scrim made compositor
        // blur behind this layer much more noticeable than the launcher itself.
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: root.requestedVisible
            onClicked: root.closeLauncher()
        }

        Rectangle {
            id: card
            width: Math.max(1, Math.min(560, parent.width - 40))
            height: Math.max(1, Math.min(560, parent.height - 64))
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: Math.max(0, Math.min(64, (parent.height - card.height) / 2))
            }
            radius: 26
            color: Config.Theme.colBg
            opacity: root.requestedVisible ? 1 : 0
            scale: root.requestedVisible ? 1 : 0.96
            border.width: 1
            border.color: Config.Theme.alpha(Config.Theme.colTextSec, 0.28)

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
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "apps"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeXl
                        color: Config.Theme.colHighlight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Applications"
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeLarge
                        font.bold: true
                    }
                    Text {
                        text: "ESC"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: Config.Theme.radiusCard
                    color: Config.Theme.alpha(Config.Theme.colTextSec, 0.10)
                    border.width: searchField.activeFocus ? 1 : 0
                    border.color: Config.Theme.colHighlight

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "search"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Config.Theme.iconSizeMd
                            color: Config.Theme.colTextSec
                        }
                        Widgets.ThemedTextField {
                            id: searchField
                            Layout.fillWidth: true
                            text: root.searchText
                            onTextChanged: {
                                root.searchText = text;
                                root.selectedIndex = 0;
                                searchDebounce.restart();
                            }
                            onTextEdited: {
                                root.keyboardNavigationActive = true;
                                root.selectedIndex = 0;
                                Qt.callLater(() => {
                                    if (root.requestedVisible && searchField.activeFocus)
                                        appList.positionViewAtIndex(0, ListView.Beginning);
                                });
                            }
                            onActiveFocusChanged: {
                                root.keyboardNavigationActive = activeFocus;
                            }
                            placeholderText: "Search applications..."
                            flat: true
                            horizontalTextPadding: 6
                            selectByMouse: true

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.closeLauncher();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.keyboardNavigationActive = true;
                                    root.selectedIndex = Math.min(root.selectedIndex + 1,
                                        Math.max(0, root.filteredApplications.length - 1));
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    root.keyboardNavigationActive = true;
                                    root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.launchSelected();
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.filteredApplications
                    currentIndex: root.selectedIndex
                    spacing: Config.Theme.spaceXs
                    ScrollBar.vertical: Widgets.ThemeScrollBar { }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: appList.width
                        height: 56
                        radius: Config.Theme.radiusCard
                        color: index === root.selectedIndex
                               ? Config.Theme.alpha(Config.Theme.colHighlight, 0.16)
                               : rowMouse.containsMouse
                                 ? Config.Theme.alpha(Config.Theme.colTextSec, 0.08)
                                 : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Config.Theme.spaceMd
                            anchors.rightMargin: 14
                            spacing: Config.Theme.spaceMd
                            IconImage {
                                implicitSize: 32
                                source: modelData.icon ? "image://icon/" + modelData.icon : ""
                                asynchronous: true
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Config.Theme.colFg
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSize
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.genericName || modelData.comment || "Application"
                                    color: Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                text: "arrow_forward"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Config.Theme.iconSizeSm
                                color: Config.Theme.colTextSec
                        visible: index === root.selectedIndex
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                if (!root.keyboardNavigationActive)
                                    root.selectedIndex = index;
                            }
                            onClicked: {
                                root.selectedIndex = index;
                                root.launchSelected();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: appList.count === 0
                        text: "No applications found"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "↑ ↓ navigate     ↵ open     ESC close"
                    color: Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
