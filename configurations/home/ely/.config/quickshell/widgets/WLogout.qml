import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import ".." as Config
import "../services" as Services

// Session menu: dims every monitor and shows a floating card, styled like the
// application launcher, on the monitor where it was opened.
Variants {
    id: root

    default property list<LogoutButton> buttons
    property int columns: 3
    property string uptimeText: ""

    model: Quickshell.screens

    function dismiss() {
        Services.WindowControl.logoutVisible = false;
        Services.WindowControl.logoutMonitor = null;
    }

    function run(button) {
        button.exec();
        dismiss();
    }

    function formatUptime(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (days > 0)
            return "Up " + days + "d " + hours + "h";
        if (hours > 0)
            return "Up " + hours + "h " + minutes + " min";
        return minutes > 0 ? "Up " + minutes + " min" : "Up less than 1 min";
    }

    property Process uptimeProcess: Process {
        command: ["cat", "/proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const seconds = Number(text.trim().split(/\s+/)[0]);
                if (Number.isFinite(seconds) && seconds >= 0)
                    root.uptimeText = root.formatUptime(Math.floor(seconds));
            }
        }
    }

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData
            readonly property bool hasCard: {
                const target = Services.WindowControl.logoutMonitor ?? Hyprland.focusedMonitor;
                return Hyprland.monitorFor(modelData) === target;
            }
            property real enterProgress: 0

            screen: modelData
            visible: Services.WindowControl.logoutVisible
            focusable: hasCard
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "session"
            WlrLayershell.keyboardFocus: visible && hasCard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            anchors {
                top: true
                left: true
                bottom: true
                right: true
            }

            Component.onCompleted: {
                openAnimation.restart();
                if (hasCard)
                    Qt.callLater(() => buttonRepeater.itemAt(0)?.forceActiveFocus());
            }

            NumberAnimation {
                id: openAnimation
                target: panel
                property: "enterProgress"
                from: 0
                to: 1
                duration: Config.Theme.motionEnter
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Theme.curveEnter
            }

            contentItem {
                focus: panel.hasCard

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismiss();
                        event.accepted = true;
                        return;
                    }
                    for (const button of root.buttons) {
                        if (event.key === button.keybind) {
                            root.run(button);
                            event.accepted = true;
                            return;
                        }
                    }
                }
            }

            // Scrim: dims the desktop on every monitor; clicking it cancels.
            Rectangle {
                anchors.fill: parent
                color: Config.Theme.alpha(Config.Colors.md3.scrim, 0.5)
                opacity: panel.enterProgress

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dismiss()
                }
            }

            Rectangle {
                id: card

                visible: panel.hasCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, cardContent.implicitWidth + 2 * Config.Theme.spaceLg + 8)
                height: Math.min(parent.height - 40, cardContent.implicitHeight + 2 * Config.Theme.spaceLg + 8)
                radius: 26
                color: Config.Theme.colBg
                border.width: 1
                border.color: Config.Theme.alpha(Config.Theme.colTextSec, 0.28)
                opacity: panel.enterProgress
                scale: 0.96 + 0.04 * panel.enterProgress

                // Swallow clicks so only the scrim dismisses.
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: cardContent

                    anchors.fill: parent
                    anchors.margins: Config.Theme.spaceLg + 4
                    spacing: Config.Theme.spaceLg

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.Theme.spaceMd

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: Config.Theme.radiusCard
                            color: Config.Theme.colHighlightContainer

                            Text {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                color: Config.Theme.colOnHighlightContainer
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Config.Theme.iconSizeXl
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Session"
                                color: Config.Theme.colFg
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeLarge
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: [Quickshell.env("USER"), root.uptimeText].filter(Boolean).join(" · ")
                                color: Config.Theme.colTextSec
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignTop
                            text: "ESC"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                        }
                    }

                    GridLayout {
                        id: buttonGrid

                        Layout.alignment: Qt.AlignHCenter
                        columns: root.columns
                        rowSpacing: Config.Theme.spaceSm
                        columnSpacing: Config.Theme.spaceSm

                        Repeater {
                            id: buttonRepeater
                            model: root.buttons

                            delegate: Item {
                                id: tile

                                required property LogoutButton modelData
                                required property int index
                                readonly property bool highlighted: activeFocus || tileMouse.containsMouse
                                readonly property color containerColor: modelData.danger
                                    ? Config.Colors.md3.error_container : Config.Theme.colHighlightContainer
                                readonly property color onContainerColor: modelData.danger
                                    ? Config.Colors.md3.on_error_container : Config.Theme.colOnHighlightContainer

                                implicitWidth: 132
                                implicitHeight: 112
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.text
                                    + (modelData.keyLabel !== "" ? ", shortcut " + modelData.keyLabel : "")

                                Keys.onPressed: event => {
                                    const count = buttonRepeater.count;
                                    const columns = buttonGrid.columns;
                                    let target = index;
                                    if (event.key === Qt.Key_Left)
                                        target = (index - 1 + count) % count;
                                    else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                                        target = (index + 1) % count;
                                    else if (event.key === Qt.Key_Up)
                                        target = index - columns >= 0 ? index - columns : index;
                                    else if (event.key === Qt.Key_Down)
                                        target = index + columns < count ? index + columns : index;
                                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                                            || event.key === Qt.Key_Space) {
                                        root.run(modelData);
                                        event.accepted = true;
                                        return;
                                    } else {
                                        return; // letters and Esc reach the window handler
                                    }
                                    buttonRepeater.itemAt(target)?.forceActiveFocus();
                                    event.accepted = true;
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Config.Theme.radiusPanel
                                    color: tile.highlighted ? tile.containerColor : Config.Theme.colSurface
                                    border.width: tile.activeFocus ? 2 : 1
                                    border.color: tile.activeFocus
                                        ? (tile.modelData.danger ? Config.Theme.colRed : Config.Theme.colHighlight)
                                        : Config.Theme.colBorderSubtle
                                    scale: tileMouse.pressed ? 0.97 : 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Config.Theme.motionFast
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Config.Theme.curveEffects
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                    }
                                }

                                // Keyboard shortcut chip.
                                Rectangle {
                                    visible: tile.modelData.keyLabel !== ""
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: Config.Theme.spaceSm
                                    width: 22
                                    height: 22
                                    radius: Config.Theme.radiusSmall
                                    color: tile.highlighted
                                        ? Config.Theme.alpha(tile.onContainerColor, 0.14)
                                        : Config.Theme.alpha(Config.Theme.colTextSec, 0.12)

                                    Text {
                                        anchors.centerIn: parent
                                        text: tile.modelData.keyLabel
                                        color: tile.highlighted ? tile.onContainerColor : Config.Theme.colTextSec
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: Config.Theme.fontSizeCaption
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Config.Theme.spaceSm

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tile.modelData.icon
                                        color: tile.highlighted ? tile.onContainerColor
                                            : (tile.modelData.danger ? Config.Theme.colRed : Config.Theme.colHighlight)
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: Config.Theme.iconSizeHero
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tile.modelData.text
                                        color: tile.highlighted ? tile.onContainerColor : Config.Theme.colFg
                                        font.family: Config.Theme.fontFamily
                                        font.pixelSize: Config.Theme.fontSize
                                    }
                                }

                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.run(tile.modelData)
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "← → ↑ ↓ navigate     ↵ select     letter = shortcut     ESC close"
                        color: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }
            }

            onVisibleChanged: {
                if (visible) {
                    openAnimation.restart();
                    root.uptimeProcess.running = true;
                    if (hasCard)
                        Qt.callLater(() => buttonRepeater.itemAt(0)?.forceActiveFocus());
                }
            }
        }
    }
}
