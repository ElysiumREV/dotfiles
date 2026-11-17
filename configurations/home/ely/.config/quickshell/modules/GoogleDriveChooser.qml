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

// Google Drive account chooser. Each account is an rclone remote mounted at
// ~/GoogleDrive/<name>; mounting, logging in and unmounting are done by
// ~/.config/hypr/scripts/gdrive.sh, which also opens this (Google Drive entry).
PanelWindow {
    id: root

    required property var targetScreen
    property bool keepVisible: false
    property int selectedIndex: 0
    property var accounts: [] // [{ name, mounted }]
    property bool loading: true
    property bool adding: false
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/gdrive.sh"
    readonly property bool requestedVisible: Services.WindowControl.googleDriveVisible
        && Hyprland.monitorFor(targetScreen) === Services.WindowControl.googleDriveMonitor

    readonly property var options: {
        const list = [];
        for (const a of root.accounts)
            list.push({ kind: "account", name: a.name, mounted: a.mounted });
        list.push({ kind: "add" });
        if (root.accounts.some(a => a.mounted))
            list.push({ kind: "unmountAll" });
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

    Process {
        id: listProc
        command: [root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.split("\n")) {
                    const parts = line.split("\t");
                    if (parts[0])
                        result.push({ name: parts[0], mounted: parts[1] === "1" });
                }
                root.accounts = result;
                root.loading = false;
            }
        }
    }

    function close() {
        Services.WindowControl.closeOverlays();
    }

    function run(args) {
        close();
        Quickshell.execDetached([root.script].concat(args));
    }

    function activate(index) {
        const option = options[index];
        if (!option)
            return;
        if (option.kind === "account")
            run(["open", option.name]);
        else if (option.kind === "unmountAll")
            run(["unmount"]);
        else if (option.kind === "add")
            startAdding();
    }

    function startAdding() {
        adding = true;
        nameField.text = root.accounts.length === 0 ? "pessoal" : "";
        Qt.callLater(() => {
            nameField.forceActiveFocus();
            nameField.selectAll();
        });
    }

    function stopAdding() {
        adding = false;
        keyHandler.forceActiveFocus();
    }

    readonly property bool nameValid: /^[A-Za-z0-9_-]+$/.test(nameField.text)
        && !root.accounts.some(a => a.name === nameField.text)

    onRequestedVisibleChanged: {
        if (requestedVisible) {
            selectedIndex = 0;
            adding = false;
            loading = true;
            listProc.running = true;
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
            const count = Math.max(1, root.options.length);
            if (event.key === Qt.Key_Escape) {
                root.close();
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                root.selectedIndex = (root.selectedIndex + 1) % count;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                root.selectedIndex = (root.selectedIndex - 1 + count) % count;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activate(root.selectedIndex);
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                root.activate(event.key - Qt.Key_1);
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
                    text: "add_to_drive"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Config.Theme.iconSizeXl
                    color: Config.Theme.colHighlight
                }
                Text {
                    Layout.fillWidth: true
                    text: "Google Drive"
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

            Text {
                Layout.fillWidth: true
                visible: root.loading
                text: "Loading accounts…"
                color: Config.Theme.colTextSec
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
            }

            Repeater {
                model: root.loading ? [] : root.options

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isAccount: modelData.kind === "account"
                    Layout.fillWidth: true
                    implicitHeight: isAccount ? 56 : 44
                    radius: Config.Theme.radiusCard
                    color: index === root.selectedIndex
                           ? Config.Theme.alpha(Config.Theme.colHighlight, 0.16)
                           : rowMouse.containsMouse
                             ? Config.Theme.alpha(Config.Theme.colTextSec, 0.08)
                             : "transparent"

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = row.index
                        onClicked: root.activate(row.index)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.Theme.spaceMd
                        anchors.rightMargin: 14
                        spacing: Config.Theme.spaceMd

                        IconImage {
                            visible: row.isAccount
                            implicitSize: 32
                            source: row.isAccount ? "image://icon/folder-gdrive" : ""
                            asynchronous: true
                        }
                        Text {
                            visible: !row.isAccount
                            Layout.preferredWidth: 32
                            horizontalAlignment: Text.AlignHCenter
                            text: row.modelData.kind === "add" ? "person_add" : "eject"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Config.Theme.iconSizeMd
                            color: Config.Theme.colTextSec
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: row.isAccount ? row.modelData.name
                                      : row.modelData.kind === "add" ? "Add account" : "Unmount all"
                                color: Config.Theme.colFg
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSize
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: row.isAccount
                                text: row.modelData.mounted ? "Mounted · ~/GoogleDrive/" + row.modelData.name : "Not mounted"
                                color: Config.Theme.colTextSec
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                        }
                        // Unmount just this account.
                        Text {
                            visible: row.isAccount && row.modelData.mounted
                            text: "eject"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Config.Theme.iconSizeMd
                            color: ejectMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colTextSec

                            MouseArea {
                                id: ejectMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                onClicked: root.run(["unmount", row.modelData.name])
                            }
                        }
                        Text {
                            visible: row.index < 9
                            text: String(row.index + 1)
                            color: row.index === root.selectedIndex ? Config.Theme.colHighlight : Config.Theme.colMuted
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            font.bold: true
                        }
                    }
                }
            }

            // Name for a new account (also the folder name under ~/GoogleDrive).
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.adding
                spacing: 6

                Widgets.ThemedTextField {
                    id: nameField
                    Layout.fillWidth: true
                    implicitHeight: 40
                    placeholderText: "Account name (e.g. pessoal, facul)"
                    Keys.onEscapePressed: root.stopAdding()
                    Keys.onReturnPressed: if (root.nameValid) root.run(["add", text])
                    Keys.onEnterPressed: if (root.nameValid) root.run(["add", text])
                }
                Text {
                    Layout.fillWidth: true
                    text: nameField.text === "" || root.nameValid
                          ? "↵ log in with Google in the browser"
                          : "Letters, numbers, - and _ only, not an existing name"
                    color: nameField.text === "" || root.nameValid ? Config.Theme.colMuted : Config.Theme.colHighlight
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !root.adding
                text: "↑ ↓ navigate     1-9 pick     ↵ open     ESC close"
                color: Config.Theme.colMuted
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
