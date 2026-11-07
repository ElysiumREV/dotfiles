import "../.." as Config
import "../../services" as Services
import "../../widgets" as Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card

    readonly property var recorder: Services.ScreenRecorder
    readonly property var microphoneNodes: Services.Volume.inputDevices
    // Values stored in settings.json: "" = none, "default_input", or a PipeWire source name.
    readonly property var microphoneValues: ["", "default_input"].concat(microphoneNodes.map(node => node.name))
    readonly property var microphoneLabels: ["No microphone", "Default microphone"]
        .concat(microphoneNodes.map(node => node.nickname || node.description || node.name))

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 2 * Config.Theme.spaceMd
    radius: Config.Theme.radiusCard
    color: Config.Theme.alpha(Config.Theme.colTextSec, 0.08)
    border.width: 1
    border.color: Config.Theme.alpha(Config.Theme.colBorder, 0.45)

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: Config.Theme.spaceMd
        spacing: Config.Theme.spaceSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceSm

            Text {
                text: "videocam"
                color: card.recorder.recording ? Config.Theme.colRed : Config.Theme.colHighlight
                font.family: "Material Symbols Rounded"
                font.pixelSize: Config.Theme.iconSizeMd
            }

            Text {
                Layout.fillWidth: true
                text: "Screen recording"
                color: Config.Theme.colFg
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSize
                font.bold: true
            }

            Text {
                visible: card.recorder.recording
                text: card.recorder.elapsedText
                color: Config.Theme.colRed
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontSizeSmall
                font.bold: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceXs
            enabled: !card.recorder.starting && !card.recorder.recording

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                text: "Screen"
                iconName: "desktop_windows"
                selected: Config.Preferences.recorder.captureMode !== "window"
                Accessible.name: "Record the focused screen"
                onClicked: Config.Preferences.recorder.captureMode = "screen"
            }

            Widgets.SegmentedTabButton {
                Layout.fillWidth: true
                text: "Window"
                iconName: "web_asset"
                selected: Config.Preferences.recorder.captureMode === "window"
                Accessible.name: "Record a window chosen in the portal picker"
                onClicked: Config.Preferences.recorder.captureMode = "window"
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Config.Preferences.recorder.captureMode === "window" && !card.recorder.starting && !card.recorder.recording
            text: "A picker opens to choose the window or monitor."
            color: Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeCaption
            wrapMode: Text.WordWrap
        }

        Widgets.ThemedComboBox {
            id: microphoneCombo
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            enabled: !card.recorder.starting && !card.recorder.recording
            popupAbove: false
            emptyText: "No microphone"
            model: card.microphoneLabels
            currentIndex: Math.max(0, card.microphoneValues.indexOf(Config.Preferences.recorder.microphone))
            Accessible.name: "Microphone used for recording"
            onActivated: index => Config.Preferences.recorder.microphone = card.microphoneValues[index]
        }

        Widgets.PreferenceSwitch {
            Layout.fillWidth: true
            implicitHeight: 34
            enabled: !card.recorder.starting && !card.recorder.recording
            text: "System audio"
            accessibleLabel: "Record the system audio"
            checked: Config.Preferences.recorder.systemAudio
            onToggled: Config.Preferences.recorder.systemAudio = checked
        }

        Widgets.ActionButton {
            Layout.fillWidth: true
            enabled: !card.recorder.stopping && (!card.recorder.checked || card.recorder.available)
            emphasized: card.recorder.starting || card.recorder.recording
            label: card.recorder.recording ? "Stop recording"
                : (card.recorder.starting ? "Cancel" : "Start recording")
            iconName: card.recorder.recording || card.recorder.starting ? "stop" : "fiber_manual_record"
            Accessible.name: label
            onClicked: card.recorder.toggle()
        }

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: card.recorder.checked && !card.recorder.available
                ? "gpu-screen-recorder is not installed." : card.recorder.message
            color: card.recorder.checked && !card.recorder.available
                ? Config.Theme.colRed : Config.Theme.colTextSec
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontSizeCaption
            wrapMode: Text.WordWrap
            elide: Text.ElideMiddle
            maximumLineCount: 2
        }
    }
}
