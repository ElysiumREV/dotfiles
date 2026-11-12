import ".." as Config
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../services" as Services
import "../widgets" as Widgets

// Asks which browser opens a link (or a new window). Links arrive through
// scripts/browser-chooser.sh, registered as the default browser; the
// SUPER+SHIFT+B bind opens it without a URL.
// Options: every Firefox profile from profiles.ini (default profile first),
// then the extra browsers below that are installed.
PanelWindow {
    id: root

    required property var targetScreen
    property bool keepVisible: false
    property int selectedIndex: 0
    property var firefoxProfiles: []
    readonly property string url: Services.WindowControl.browserChooserUrl
    readonly property bool requestedVisible: Services.WindowControl.browserChooserVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.browserChooserMonitor

    // Non-Firefox browsers, shown only when their desktop entry exists.
    readonly property var extraBrowsers: [
        { desktopId: "google-chrome", label: "Google Chrome", detail: "Work / study",
          command: ["google-chrome-stable"], newWindowFlag: "--new-window" }
    ]

    readonly property var options: {
        const list = [];
        const firefox = DesktopEntries.byId("firefox");
        if (firefox) {
            for (const profile of root.firefoxProfiles) {
                list.push({
                    label: "Firefox",
                    detail: profile.name + (profile.isDefault ? " · default profile" : ""),
                    icon: firefox.icon,
                    command: ["firefox", "-P", profile.name],
                    newWindowFlag: "--new-window"
                });
            }
        }
        for (const browser of root.extraBrowsers) {
            const entry = DesktopEntries.byId(browser.desktopId);
            if (entry)
                list.push(Object.assign({ icon: entry.icon }, browser));
        }
        return list;
    }

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
        dismissAction: () => root.close()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/mozilla/firefox/profiles.ini"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.firefoxProfiles = root.parseProfiles(text())
    }

    // [ProfileN] sections hold Name/Path; [Install*] sections point Default at
    // the Path of the profile Firefox opens by default.
    function parseProfiles(ini) {
        const profiles = [];
        const defaults = new Set();
        let section = "";
        let current = null;
        for (const raw of ini.split("\n")) {
            const line = raw.trim();
            const header = line.match(/^\[(.+)\]$/);
            if (header) {
                section = header[1];
                current = section.startsWith("Profile") ? { name: "", path: "" } : null;
                if (current)
                    profiles.push(current);
                continue;
            }
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            const key = line.slice(0, eq);
            const value = line.slice(eq + 1);
            if (current && key === "Name")
                current.name = value;
            else if (current && key === "Path")
                current.path = value;
            else if (section.startsWith("Install") && key === "Default")
                defaults.add(value);
        }
        return profiles.filter(p => p.name !== "")
            .map(p => ({ name: p.name, isDefault: defaults.has(p.path) }))
            .sort((a, b) => (b.isDefault - a.isDefault) || a.name.localeCompare(b.name));
    }

    function close() {
        Services.WindowControl.closeOverlays();
    }

    function launch(index) {
        const option = options[index];
        if (!option)
            return;
        const args = url !== "" ? [url] : [option.newWindowFlag];
        close();
        Quickshell.execDetached(option.command.concat(args));
    }

    onRequestedVisibleChanged: {
        if (requestedVisible) {
            selectedIndex = 0;
            Qt.callLater(() => {
                if (root.requestedVisible)
                    keyHandler.forceActiveFocus();
            });
        }
    }

    Item {
        id: keyHandler
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                root.selectedIndex = (root.selectedIndex + 1) % Math.max(1, root.options.length);
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                const count = Math.max(1, root.options.length);
                root.selectedIndex = (root.selectedIndex - 1 + count) % count;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.launch(root.selectedIndex);
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                root.launch(event.key - Qt.Key_1);
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.requestedVisible
        onClicked: root.close()
    }

    Rectangle {
        id: card
        width: Math.max(1, Math.min(440, parent.width - 40))
        height: content.implicitHeight + 40
        anchors.centerIn: parent
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
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20
            }
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "public"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Config.Theme.iconSizeXl
                    color: Config.Theme.colHighlight
                }
                Text {
                    Layout.fillWidth: true
                    text: "Open with"
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
                implicitHeight: 40
                radius: Config.Theme.radiusCard
                color: Config.Theme.alpha(Config.Theme.colTextSec, 0.10)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: root.url !== "" ? "link" : "add"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.Theme.iconSizeMd
                        color: Config.Theme.colTextSec
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.url !== "" ? root.url : "New window"
                        color: root.url !== "" ? Config.Theme.colFg : Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideMiddle
                    }
                }
            }

            Repeater {
                model: root.options

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 56
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
                                text: modelData.label
                                color: Config.Theme.colFg
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSize
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.detail
                                color: Config.Theme.colTextSec
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            visible: index < 9
                            text: String(index + 1)
                            color: index === root.selectedIndex ? Config.Theme.colHighlight : Config.Theme.colMuted
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: root.launch(index)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.options.length === 0
                text: "No browsers found"
                color: Config.Theme.colTextSec
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "↑ ↓ navigate     1-9 pick     ↵ open     ESC close"
                color: Config.Theme.colMuted
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
