import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import Quickshell.Wayland
import "../." as Config
import "../services" as Services
import "../modules/PopupGeometry.js" as PopupGeometry
import "../widgets" as Widgets

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(
        screen => Hyprland.monitorFor(screen) === Hyprland.focusedMonitor
    ) ?? Quickshell.screens[0] ?? null

    LazyLoader {
        activeAsync: !Services.Notifications.doNotDisturb
            && !Services.Notifications.centerVisible
            && Services.Notifications.popupNotifications.length > 0

        PanelWindow {
            id: popupWindow

        screen: root.focusedScreen
        color: "transparent"
        visible: !Services.Notifications.doNotDisturb
            && !Services.Notifications.centerVisible
            && Services.Notifications.popupNotifications.length > 0
        implicitWidth: PopupGeometry.widthForScreen(root.focusedScreen, 360, 24)
        implicitHeight: PopupGeometry.heightForScreen(
            root.focusedScreen, popupColumn.implicitHeight, Config.Theme.barHeight + 12, 16
        )
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            right: true
        }

        margins {
            top: Config.Theme.barHeight + 12
            right: 16
        }

        Flickable {
            id: popupScroll
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: popupColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            // Popups are transient and limited to a few cards; no visible scrollbar
            // (the wheel still scrolls if a tiny screen clips the stack).
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

            Column {
                id: popupColumn
                width: popupScroll.width
                spacing: Config.Theme.spaceSm
            Repeater {
                model: Services.Notifications.doNotDisturb
                    ? [] : Services.Notifications.popupNotifications.slice(0, 5)

                delegate: Rectangle {
                    id: card
                    required property var modelData

                    readonly property string iconName: Services.Notifications.iconNameOf(modelData)
                    readonly property string iconSource: Services.Notifications.iconSourceOf(modelData)
                    readonly property string attachment: Services.Notifications.attachmentOf(modelData)
                    property bool isAvatar: card.iconName === "" && card.attachment !== "" && modelData.body === ""
                    readonly property int timeoutMs: modelData.expireTimeout === 0 ? 0
                        : modelData.expireTimeout < 0
                            ? Math.max(1, Math.min(10, Config.Preferences.notifications.defaultTimeoutSeconds)) * 1000
                            : Math.max(1, Math.round(modelData.expireTimeout))
                        width: popupColumn.width
                    implicitHeight: cardContent.implicitHeight + 24
                    radius: Config.Theme.radiusCard
                    color: cardHover.hovered
                        ? Qt.tint(Config.Theme.colBg, Config.Theme.alpha(Config.Theme.colHighlight, 0.06))
                        : Config.Theme.colBg
                    border.width: 1
                    border.color: modelData.urgency === NotificationUrgency.Critical
                        ? Config.Theme.colRed
                        : Config.Theme.alpha(Config.Theme.colTextSec, 0.25)

                    // Hovering pauses the timeout; after the pointer leaves, the popup
                    // stays a little longer instead of resuming the full duration.
                    readonly property int hoverGraceMs: 3000
                    property bool wasHovered: false

                    Timer {
                        id: expireTimer
                        interval: card.wasHovered ? card.hoverGraceMs : card.timeoutMs
                        // Expiration must not depend on the layer window's visible
                        // state: it can briefly report false while being created or
                        // reconfigured, which would pause the timeout indefinitely.
                        running: card.timeoutMs > 0 && !cardHover.hovered
                        onTriggered: Services.Notifications.expirePopup(modelData.id)
                    }

                    HoverHandler {
                        id: cardHover
                        onHoveredChanged: if (!hovered) card.wasHovered = true
                    }

                    // Click the notification itself: default action / focus the app.
                    // Right or middle click dismisses it. Buttons on top keep their clicks.
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton)
                                Services.Notifications.activate(modelData.id);
                            else
                                Services.Notifications.dismiss(modelData.id);
                        }
                    }

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: Config.Theme.spaceMd
                        spacing: 7

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 9

                            Rectangle {
                                id: previewContainer
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: Config.Theme.radiusControl
                                color: Config.Theme.alpha(Config.Theme.colHighlight, 0.14)
                                // Show tiny icon only when we have a real appIcon or an avatar image.
                                visible: card.iconName !== "" || isAvatar

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 19
                                    source: card.iconSource !== "" ? card.iconSource : (isAvatar ? card.attachment : "")
                                    asynchronous: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    // Placeholder when the app icon cannot be resolved and there is no avatar.
                                    visible: card.iconSource === "" && !isAvatar
                                    text: "notifications"
                                    color: Config.Theme.colHighlight
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Config.Theme.iconSizeSm
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appName || "Notification"
                                    color: Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeCaption
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary || ""
                                    visible: text !== ""
                                    color: Config.Theme.colFg
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: Config.Theme.fontSizeSmall
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }

                            Widgets.IconButton {
                                iconName: "close"
                                iconSize: Config.Theme.iconSizeSm
                                buttonRadius: 7
                                implicitWidth: Config.Theme.controlMinSize
                                implicitHeight: Config.Theme.controlMinSize
                                Accessible.name: "Dismiss notification from " + (modelData.appName || "Notification")
                                onClicked: Services.Notifications.dismiss(modelData.id)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: modelData.body !== ""
                            text: modelData.body
                            textFormat: Text.PlainText
                            color: Config.Theme.colTextSec
                            wrapMode: Text.Wrap
                            maximumLineCount: 5
                            elide: Text.ElideRight
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? 132 : 0
                            visible: card.attachment !== "" && !isAvatar
                            radius: Config.Theme.radiusControl
                            clip: true
                            color: Config.Theme.alpha(Config.Theme.colTextSec, 0.08)

                            Image {
                                anchors.fill: parent
                                source: card.attachment
                                sourceSize.width: 672
                                sourceSize.height: 264
                                asynchronous: true
                                cache: false
                                fillMode: Image.PreserveAspectFit
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        previewContainer.visible = false;
                                    }
                                }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: Services.Notifications.buttonActionsOf(modelData).length > 0

                            Repeater {
                                model: Services.Notifications.buttonActionsOf(modelData)
                                delegate: Widgets.LabelButton {
                                    required property var modelData
                                    text: modelData.text
                                    Accessible.name: modelData.text
                                    implicitHeight: 27
                                    labelFontSize: 10
                                    contentHorizontalPadding: 9
                                    cornerRadius: 7
                                    idleTextColor: Config.Theme.colFg
                                    hoverTextColor: Config.Theme.colFg
                                    idleBackgroundColor: Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
                                    hoverBackgroundColor: Config.Theme.alpha(Config.Theme.colHighlight, 0.22)
                                    onClicked: modelData.invoke()
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }
}
}
