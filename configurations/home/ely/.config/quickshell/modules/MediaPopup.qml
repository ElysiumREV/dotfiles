import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Config

PanelWindow {
    id: root

    required property var media
    required property var positionProvider
    property real popupX: 0

    color: "transparent"
    visible: false
    implicitWidth: 360
    implicitHeight: 210
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        left: root.popupX
    }

    function openPopup() {
        popupX = positionProvider(implicitWidth).x
        visible = true
    }

    PopupDismissBehavior { popup: root }

    Rectangle {
        anchors.fill: parent
        color: Config.Theme.colBg
        radius: 12
        border.width: 1
        border.color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.25)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.media.displayName
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "close"
                    color: closeMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colTextSec
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 19

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    radius: 8
                    clip: true
                    color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        color: Config.Theme.colTextSec
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 34
                        visible: cover.status !== Image.Ready
                    }

                    Image {
                        id: cover
                        anchors.fill: parent
                        source: root.media.artUrl
                        sourceSize.width: 160
                        sourceSize.height: 160
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.media.title || "Nothing playing"
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.media.artist || "Unknown artist"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.media.album || "Unknown album"
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall - 1
                        elide: Text.ElideRight
                        visible: root.media.album !== ""
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                ControlButton {
                    iconName: "skip_previous"
                    available: root.media.canPrevious
                    onClicked: root.media.previous()
                }

                ControlButton {
                    iconName: root.media.playing ? "pause" : "play_arrow"
                    available: root.media.canToggle
                    emphasized: true
                    onClicked: root.media.togglePlayPause()
                }

                ControlButton {
                    iconName: "skip_next"
                    available: root.media.canNext
                    onClicked: root.media.next()
                }
            }
        }
    }

    component ControlButton: Rectangle {
        id: control

        required property string iconName
        required property bool available
        property bool emphasized: false
        signal clicked()

        implicitWidth: 36
        implicitHeight: 36
        width: 36
        height: 36
        radius: width / 2
        color: emphasized
            ? Config.Theme.colHighlight
            : (controlMouse.containsMouse && available
                ? Qt.rgba(Config.Theme.colFg.r, Config.Theme.colFg.g, Config.Theme.colFg.b, 0.12)
                : "transparent")
        opacity: available ? 1 : 0.38

        Text {
            anchors.centerIn: parent
            text: control.iconName
            color: control.emphasized ? Config.Theme.colBg : Config.Theme.colFg
            font.family: "Material Symbols Rounded"
            font.pixelSize: control.emphasized ? 22 : 20
        }

        MouseArea {
            id: controlMouse
            anchors.fill: parent
            enabled: control.available
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: control.clicked()
        }
    }
}
