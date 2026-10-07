import ".." as Config
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../services" as Services

PanelWindow {
    id: root

    required property var targetScreen
    property var applications: []
    property var indexedApplications: []
    property int selectedIndex: 0
    property string searchText: ""
    property bool keyboardNavigationActive: false

    color: "transparent"
    screen: targetScreen
    visible: Services.WindowControl.launcherVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.launcherMonitor
    focusable: visible
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function refreshApplications() {
        const entries = DesktopEntries.applications.values ?? [];
        root.applications = entries.filter(entry => !entry.noDisplay && entry.name)
            .sort((a, b) => a.name.localeCompare(b.name));
        root.indexedApplications = root.applications.map(entry => ({
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
        // Depend on the cache revision so launch counts update the blank-query order.
        const usageRevision = Services.ApplicationUsage.revision;
        const tokens = root.normalizeSearchText(root.searchText).split(/\s+/).filter(Boolean);
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
                usageCount: Services.ApplicationUsage.countFor(item.id),
                lastUsed: Services.ApplicationUsage.lastUsedFor(item.id)
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
        selectedIndex = 0;
        keyboardNavigationActive = true;
        Services.WindowControl.openLauncher(Hyprland.monitorFor(targetScreen));
    }

    function closeLauncher() {
        searchText = "";
        selectedIndex = 0;
        keyboardNavigationActive = false;
        Services.WindowControl.launcherVisible = false;
        Services.WindowControl.launcherMonitor = null;
    }

    onVisibleChanged: {
        if (visible) {
            keyboardNavigationActive = true;
            Qt.callLater(() => searchField.forceActiveFocus());
        } else {
            searchText = "";
            selectedIndex = 0;
            keyboardNavigationActive = false;
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

    Component.onCompleted: refreshApplications()
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.refreshApplications(); }
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeLauncher()
        }

        Rectangle {
            id: card
            width: Math.min(560, parent.width - 40)
            height: Math.min(560, parent.height - 64)
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
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "apps"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
                        color: Config.Theme.colHighlight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Aplicativos"
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
                    radius: 11
                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                   Config.Theme.colTextSec.b, 0.10)
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
                            font.pixelSize: 20
                            color: Config.Theme.colTextSec
                        }
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            text: root.searchText
                            onTextChanged: {
                                root.searchText = text;
                                root.selectedIndex = 0;
                            }
                            onTextEdited: {
                                root.keyboardNavigationActive = true;
                                root.selectedIndex = 0;
                                Qt.callLater(() => {
                                    if (root.visible && searchField.activeFocus)
                                        appList.positionViewAtIndex(0, ListView.Beginning);
                                });
                            }
                            onActiveFocusChanged: {
                                root.keyboardNavigationActive = activeFocus;
                            }
                            placeholderText: "Buscar aplicativos..."
                            color: Config.Theme.colFg
                            placeholderTextColor: Config.Theme.colMuted
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSize
                            background: null
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
                    spacing: 4
                    ScrollBar.vertical: ScrollBar { }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: appList.width
                        height: 56
                        radius: 10
                        color: index === root.selectedIndex
                               ? Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                         Config.Theme.colHighlight.b, 0.16)
                               : rowMouse.containsMouse
                                 ? Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                           Config.Theme.colTextSec.b, 0.08)
                                 : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 14
                            spacing: 12

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
                                    text: modelData.genericName || modelData.comment || "Aplicativo"
                                    color: Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                text: "arrow_forward"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
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
                        text: "Nenhum aplicativo encontrado"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "↑ ↓ navegar     ↵ abrir     ESC fechar"
                    color: Config.Theme.colMuted
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
