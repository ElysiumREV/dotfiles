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
            ScrollBar.vertical: Widgets.ThemeScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: popupColumn
                width: popupScroll.width
                spacing: 8

            Repeater {
                model: Services.Notifications.doNotDisturb
                    ? [] : Services.Notifications.popupNotifications.slice(0, 5)

                delegate: Rectangle {
                    id: card
                    required property var modelData

                    property bool isAvatar: modelData.appIcon === "" && modelData.image !== "" && modelData.body === ""
                    readonly property int timeoutMs: modelData.expireTimeout === 0 ? 0
                        : modelData.expireTimeout < 0
                            ? Math.max(1, Math.min(10, Config.Preferences.notifications.defaultTimeoutSeconds)) * 1000
                            : Math.max(1, Math.round(modelData.expireTimeout))
                        width: popupColumn.width
                    implicitHeight: cardContent.implicitHeight + 24
                    radius: 12
                    color: Config.Theme.colBg
                    border.width: 1
                    border.color: modelData.urgency === NotificationUrgency.Critical
                        ? Config.Theme.colRed
                        : Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                  Config.Theme.colTextSec.b, 0.25)

                    Timer {
                        interval: card.timeoutMs
                        // Expiration must not depend on the layer window's visible
                        // state: it can briefly report false while being created or
                        // reconfigured, which would pause the timeout indefinitely.
                        running: interval > 0
                        onTriggered: Services.Notifications.expirePopup(modelData.id)
                    }

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 7

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 9

                            Rectangle {
                                id: previewContainer
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 8
                                color: Qt.rgba(Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                               Config.Theme.colHighlight.b, 0.14)
                                // Show tiny icon only when we have a real appIcon or an avatar image.
                                visible: modelData.appIcon !== "" || isAvatar

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 19
                                    source: modelData.appIcon !== ""
                                        ? (modelData.appIcon.includes(":") || modelData.appIcon.includes("/")
                                           ? modelData.appIcon : "image://icon/" + modelData.appIcon) : (isAvatar ? modelData.image : "")
                                    asynchronous: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    // Show generic placeholder only when no appIcon and not an avatar.
                                    visible: modelData.appIcon === "" && !isAvatar
                                    text: "notifications"
                                    color: Config.Theme.colHighlight
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appName || "Notificação"
                                    color: Config.Theme.colTextSec
                                    font.family: Config.Theme.fontFamily
                                    font.pixelSize: 10
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
                                iconSize: 17
                                buttonRadius: 7
                                implicitWidth: 28
                                implicitHeight: 28
                                Accessible.name: "Dispensar notificação de " + (modelData.appName || "Notificação")
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
                            visible: modelData.image !== "" && !isAvatar
                            radius: 8
                            clip: true
                            color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                           Config.Theme.colTextSec.b, 0.08)

                            Image {
                                anchors.fill: parent
                                source: modelData.image
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
                            visible: modelData.actions.length > 0

                            Repeater {
                                model: modelData.actions
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
                                    idleBackgroundColor: Qt.rgba(
                                        Config.Theme.colTextSec.r, Config.Theme.colTextSec.g,
                                        Config.Theme.colTextSec.b, 0.12
                                    )
                                    hoverBackgroundColor: Qt.rgba(
                                        Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                                        Config.Theme.colHighlight.b, 0.22
                                    )
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
