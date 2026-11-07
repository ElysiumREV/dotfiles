import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../." as Config
import "../services" as Services
import "../widgets" as Widgets

PanelWindow {
    id: root

    required property var targetScreen
    property bool keepVisible: false
    property string searchText: ""
    property int selectedIndex: 0
    readonly property var filteredEntries: {
        const query = searchText.trim().toLocaleLowerCase();
        return Services.ClipboardHistory.entries.filter(entry =>
            !query || entry.text.toLocaleLowerCase().includes(query));
    }
    readonly property bool requestedVisible: Services.WindowControl.clipboardVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.clipboardMonitor

    screen: targetScreen
    color: "transparent"
    visible: requestedVisible || keepVisible
    focusable: requestedVisible
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: requestedVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    Widgets.FocusDismissBehavior {
        window: root
        active: root.requestedVisible
        dismissAction: () => root.closeMenu()
    }

    function closeMenu(): void {
        searchText = "";
        Services.WindowControl.closeOverlays();
    }

    function copyEntry(text): void {
        Quickshell.clipboardText = text;
        closeMenu();
    }

    function moveSelection(offset): void {
        if (filteredEntries.length === 0) {
            selectedIndex = 0;
            return;
        }
        selectedIndex = (selectedIndex + offset + filteredEntries.length) % filteredEntries.length;
        historyList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function syncRequestedVisibility() {
        if (requestedVisible) {
            searchText = "";
            Qt.callLater(() => {
                if (root.requestedVisible)
                    searchField.forceActiveFocus();
            });
        } else {
            searchText = "";
        }
    }

    Component.onCompleted: syncRequestedVisibility()
    onRequestedVisibleChanged: syncRequestedVisibility()

    Rectangle {
        anchors.fill: parent
        enabled: root.requestedVisible
        // Keep the desktop visible like the application launcher.
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: root.requestedVisible
            onClicked: root.closeMenu()
        }

        Rectangle {
            id: card
            width: Math.max(1, Math.min(580, parent.width - 36))
            height: Math.max(1, Math.min(620, parent.height - 48))
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: Math.max(0, Math.min(64, (parent.height - card.height) / 2))
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
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "content_paste"
                        color: Config.Theme.colHighlight
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeXl
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Clipboard history"
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeLarge
                        font.bold: true
                    }
                    Widgets.LabelButton {
                        id: clearButton
                        text: "Clear"
                        labelFontSize: Config.Theme.fontSizeSmall
                        idleTextColor: Config.Theme.colTextSec
                        hoverTextColor: Config.Theme.colOnHighlightContainer
                        disabledTextColor: Config.Theme.colMuted
                        hoverBackgroundColor: Config.Theme.colHighlightContainer
                        outlineOnFocus: true
                        activeFocusOnTab: true
                        Keys.onEscapePressed: root.closeMenu()
                        enabled: Services.ClipboardHistory.entries.length > 0
                        onClicked: {
                            Services.ClipboardHistory.clear();
                            searchField.forceActiveFocus();
                        }
                    }
                    Widgets.IconButton {
                        id: closeButton
                        iconName: "close"
                        iconSize: Config.Theme.iconSizeMd
                        activeFocusOnTab: true
                        Keys.onEscapePressed: root.closeMenu()
                        onClicked: root.closeMenu()
                    }
                }

                Widgets.ThemedTextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    placeholderText: "Filter history..."
                    text: root.searchText
                    onTextChanged: {
                        root.searchText = text;
                        root.selectedIndex = 0;
                    }
                    fieldRadius: 11
                    horizontalTextPadding: 14
                    selectByMouse: true
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeMenu();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            const entry = root.filteredEntries[root.selectedIndex];
                            if (entry)
                                root.copyEntry(entry.text);
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: Services.ClipboardHistory.entries.length === 0
                    text: "History appears here while QuickShell is running."
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                ListView {
                    id: historyList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 7
                    model: root.filteredEntries
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: Widgets.ThemeScrollBar { }

                    delegate: ItemDelegate {
                        id: itemDelegate
                        required property var modelData
                        required property int index
                        width: historyList.width
                        height: Math.max(58, preview.implicitHeight + 22)
                        padding: 11
                        highlighted: root.selectedIndex === index
                        activeFocusOnTab: true
                        onClicked: root.copyEntry(modelData.text)
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.closeMenu();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                                root.moveSelection(event.key === Qt.Key_Down ? 1 : -1);
                                const nextItem = historyList.itemAtIndex(root.selectedIndex);
                                if (nextItem)
                                    nextItem.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                        background: Rectangle {
                            radius: Config.Theme.radiusControl
                            color: itemDelegate.highlighted || itemDelegate.hovered || itemDelegate.activeFocus
                                ? Config.Theme.alpha(Config.Theme.colHighlight, 0.13)
                                : Config.Theme.alpha(Config.Theme.colTextSec, 0.08)
                            border.width: itemDelegate.activeFocus ? 1 : 0
                            border.color: Config.Theme.colHighlight
                        }

                        Text {
                            id: preview
                            anchors.fill: parent
                            anchors.margins: 0
                            text: modelData.text.replace(/[\r\n\t]+/g, " ")
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "↑ ↓ select · Enter copy · Tab actions · Esc close · up to 50 items"
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
