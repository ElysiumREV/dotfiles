import "../.." as Config
import "../../services" as Services
import "../../widgets" as Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire

ColumnLayout {
    required property var menu
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Config.Theme.spaceXs
    RowLayout {
        Layout.fillWidth: true

        Text {
            text: Services.Volume.effectivelyMuted ? "volume_off" : "volume_up"
            color: Config.Theme.colHighlight
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.Theme.iconSizeMd
        }

        Text {
            Layout.fillWidth: true
            text: "Volume"
            color: Config.Theme.colFg
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSize
            font.bold: true
        }

        Text {
            text: Services.Volume.percentage + "%"
            color: Config.Theme.colMuted
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
        }

        Widgets.IconButton {
            id: muteVolumeButton
            iconName: Services.Volume.effectivelyMuted ? "volume_up" : "volume_off"
            iconSize: Config.Theme.iconSizeSm
            buttonRadius: 7
            implicitWidth: Config.Theme.controlMinSize
            implicitHeight: Config.Theme.controlMinSize
            Accessible.name: Services.Volume.effectivelyMuted ? "Unmute audio" : "Mute audio"
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered
            onClicked: Services.Volume.toggleMute()
        }

        Widgets.IconButton {
            id: advancedAudioButton
            iconName: "tune"
            iconSize: Config.Theme.iconSizeSm
            buttonRadius: 7
            implicitWidth: Config.Theme.controlMinSize
            implicitHeight: Config.Theme.controlMinSize
            Accessible.name: "Open advanced audio options"
            ToolTip.text: "Advanced options"
            ToolTip.visible: hovered
            onClicked: Quickshell.execDetached(["pavucontrol"])
        }
    }

    Widgets.ThemedSlider {
        id: volumeSlider
        Layout.fillWidth: true
        from: 0
        to: 1
        value: Services.Volume.volume
        Accessible.name: "Output volume"
        onMoved: Services.Volume.setVolume(value)

        Connections {
            target: Services.Volume
            function onVolumeChanged() {
                volumeSlider.value = Services.Volume.volume;
            }
        }
    }

    ScrollView {
        id: appVolumeScroll
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.preferredHeight: menu.outputAppNodes.length > 0 ? 180 : 0
        visible: menu.outputAppNodes.length > 0
        clip: true
        contentWidth: availableWidth
        contentHeight: appVolumeRows.implicitHeight
        ScrollBar.vertical: Widgets.ThemeScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: appVolumeRows
            width: appVolumeScroll.availableWidth
            spacing: Config.Theme.spaceSm
            Repeater {
                model: ScriptModel {
                    values: menu.outputAppNodes
                }

                delegate: RowLayout {
                    id: appVolumeRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Config.Theme.spaceSm
                    PwObjectTracker { objects: [appVolumeRow.modelData] }

                    Widgets.IconButton {
                        iconName: appVolumeRow.modelData.audio?.muted ? "volume_off" : "volume_up"
                        iconSize: Config.Theme.iconSizeSm
                        buttonRadius: 8
                        idleIconColor: appVolumeRow.modelData.audio?.muted
                            ? Config.Theme.colMuted : Config.Theme.colHighlight
                        implicitWidth: Config.Theme.controlMinSize
                        implicitHeight: Config.Theme.controlMinSize
                        Accessible.name: "Mute " + menu.audioAppName(appVolumeRow.modelData)
                        onClicked: menu.toggleAppMute(appVolumeRow.modelData)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: menu.audioAppName(appVolumeRow.modelData)
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }

                        Widgets.ThemedSlider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1
                            stepSize: 0.01
                            value: appVolumeRow.modelData.audio?.volume ?? 0
                            Accessible.name: "Volume for " + menu.audioAppName(appVolumeRow.modelData)
                            onMoved: menu.setAppVolume(appVolumeRow.modelData, value)
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Services.Volume.captureApplications.length > 0
        spacing: Config.Theme.spaceSm
        Text {
            text: Services.Volume.microphoneMuted ? "mic_off" : "mic"
            color: Services.Volume.microphoneMuted ? Config.Theme.colTextSec : Config.Theme.colRed
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.Theme.iconSizeSm
        }

        Text {
            Layout.fillWidth: true
            text: Services.Volume.captureApplications.join(", ")
            color: Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            elide: Text.ElideRight
        }

        Widgets.LabelButton {
            text: Services.Volume.microphoneMuted ? "Unmute" : "Mute"
            labelFontSize: Config.Theme.fontSizeSmall
            idleTextColor: Config.Theme.colFg
            hoverTextColor: Config.Theme.colBg
            idleBackgroundColor: Config.Theme.alpha(Config.Theme.colTextSec, 0.12)
            hoverBackgroundColor: Config.Theme.colHighlight
            cornerRadius: 7
            Accessible.name: Services.Volume.microphoneMuted
                ? "Unmute microphone" : "Mute microphone"
            onClicked: Services.Volume.toggleMicrophoneMute()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Services.PrivacyIndicators.cameraApplications.length > 0
        spacing: Config.Theme.spaceSm
        Text {
            text: "videocam"
            color: Config.Theme.colRed
            font.family: "Material Symbols Rounded"
            font.pixelSize: Config.Theme.iconSizeSm
        }

        Text {
            Layout.fillWidth: true
            text: Services.PrivacyIndicators.cameraApplications.join(", ")
            color: Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.Theme.spaceSm
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: Config.Theme.radiusCard
            color: Config.Theme.alpha(Config.Theme.colTextSec, 0.08)
            border.width: 1
            border.color: outputDeviceCombo.activeFocus || outputDeviceCombo.popup.visible
                ? Config.Theme.colHighlight
                : Config.Theme.alpha(Config.Theme.colBorder, 0.45)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 7
                spacing: 1

                Text {
                    text: "AUDIO OUTPUT"
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeCaption
                    font.letterSpacing: 0.5
                }

                Widgets.ThemedComboBox {
                    id: outputDeviceCombo
                    emptyText: "No output device"
                    Layout.fillWidth: true
                    enabled: menu.outputDevices.length > 0
                    model: menu.outputDevices.map(node => menu.audioNodeName(node))
                    currentIndex: menu.audioDeviceIndex(
                        menu.outputDevices,
                        menu.pipewire.preferredDefaultAudioSink,
                        menu.pipewire.defaultAudioSink
                    )
                    onActivated: index => menu.selectOutputDevice(index)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: Config.Theme.radiusCard
            color: Config.Theme.alpha(Config.Theme.colTextSec, 0.08)
            border.width: 1
            border.color: inputDeviceCombo.activeFocus || inputDeviceCombo.popup.visible
                ? Config.Theme.colHighlight
                : Config.Theme.alpha(Config.Theme.colBorder, 0.45)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 7
                spacing: 1

                Text {
                    text: "AUDIO INPUT"
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeCaption
                    font.letterSpacing: 0.5
                }

                Widgets.ThemedComboBox {
                    id: inputDeviceCombo
                    emptyText: "No input device"
                    Layout.fillWidth: true
                    enabled: menu.inputDevices.length > 0
                    model: menu.inputDevices.map(node => menu.audioNodeName(node))
                    currentIndex: menu.audioDeviceIndex(
                        menu.inputDevices,
                        menu.pipewire.preferredDefaultAudioSource,
                        menu.pipewire.defaultAudioSource
                    )
                    onActivated: index => menu.selectInputDevice(index)
                }
            }
        }
    }
}
