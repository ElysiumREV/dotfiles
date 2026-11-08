import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Config
import "../services" as Services
import "../widgets" as Widgets
import "./PopupGeometry.js" as PopupGeometry

PanelWindow {
    id: root

    required property var targetScreen
    required property var positionProvider
    property real popupRight: 16
    property real enterProgress: 0

    readonly property var volumeService: Services.Volume
    readonly property string outputName: volumeService.audioSink?.description
        || volumeService.audioSink?.name || "Sem dispositivo de saída"
    readonly property string inputName: volumeService.audioSource?.description
        || volumeService.audioSource?.name || "Sem dispositivo de entrada"
    readonly property var captureApplications: volumeService.captureApplications

    screen: targetScreen
    color: "transparent"
    visible: false
    focusable: visible
    implicitWidth: PopupGeometry.widthForScreen(targetScreen, 360, 24)
    implicitHeight: 350
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: Config.Theme.barHeight + 8
        right: root.popupRight
    }

    Widgets.FocusDismissBehavior {
        window: root
        dismissAction: () => root.closeMenu()
    }

    function openMenu(): void {
        const position = positionProvider(implicitWidth)
        popupRight = position?.right ?? 16
        visible = true
    }

    function closeMenu(): void {
        visible = false
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "enterProgress"
        from: 0
        to: 1
        duration: Config.Theme.motionEnter
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.Theme.curveEnter
    }

    onVisibleChanged: {
        if (visible) {
            openAnimation.restart()
            Qt.callLater(() => volumeSlider.forceActiveFocus())
        } else {
            enterProgress = 0
        }
    }

    contentItem {
        focus: root.visible
        Keys.onEscapePressed: root.closeMenu()
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.enterProgress
        transform: Translate { y: (1 - root.enterProgress) * -10 }
        color: Config.Theme.colBg
        radius: 16
        border.width: 1
        border.color: Config.Theme.colBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Áudio"
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeLarge
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.outputName
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }
                }

                Widgets.IconButton {
                    id: closeButton
                    iconName: "close"
                    implicitWidth: 32
                    implicitHeight: 32
                    activeFocusOnTab: true
                    Accessible.name: "Fechar menu de áudio"
                    onClicked: root.closeMenu()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 11
                color: Config.Colors.md3.surface_container
                implicitHeight: outputContent.implicitHeight + 22

                ColumnLayout {
                    id: outputContent
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Saída de áudio"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            font.bold: true
                        }
                        Text {
                            text: volumeService.effectivelyMuted ? "Mudo" : volumeService.percentage + "%"
                            color: Config.Theme.colFg
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSize
                            font.bold: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Widgets.ThemedSlider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            activeFocusOnTab: true
                            from: 0
                            to: 1
                            stepSize: 0.01
                            value: volumeService.volume
                            enabled: volumeService.audioIface !== null
                            Accessible.name: "Volume de saída"
                            onMoved: volumeService.setVolume(value)
                        }

                        Widgets.IconButton {
                            id: outputMuteButton
                            iconName: volumeService.effectivelyMuted ? "volume_off" : "volume_up"
                            iconSize: 20
                            buttonRadius: 9
                            filled: true
                            idleIconColor: Config.Theme.colFg
                            implicitWidth: 38
                            implicitHeight: 36
                            activeFocusOnTab: true
                            Accessible.name: volumeService.effectivelyMuted ? "Ativar áudio" : "Silenciar saída"
                            onClicked: volumeService.toggleMute()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 11
                color: Config.Colors.md3.surface_container
                implicitHeight: microphoneContent.implicitHeight + 22

                ColumnLayout {
                    id: microphoneContent
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Microfone"
                            color: Config.Theme.colTextSec
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: Config.Theme.fontSizeSmall
                            font.bold: true
                        }
                        Text {
                            text: volumeService.microphoneMuted ? "MUTADO"
                                : (root.captureApplications.length > 0 ? "EM USO" : "LIVRE")
                            color: volumeService.microphoneMuted ? Config.Theme.colRed
                                : (root.captureApplications.length > 0 ? Config.Theme.colYellow
                                   : Config.Theme.colTextSec)
                            font.family: Config.Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.inputName
                        color: Config.Theme.colFg
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.captureApplications.length > 0
                            ? "Captura conectada por: " + root.captureApplications.join(", ")
                            : "Nenhum aplicativo conectado ao microfone."
                        color: Config.Theme.colTextSec
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: Config.Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignTop
                    }

                    Text {
                        Layout.fillWidth: true
                        text: volumeService.microphoneMuted
                            ? "O microfone está silenciado na barra."
                            : "O ícone da barra silencia o microfone durante a captura."
                        color: Config.Theme.colMuted
                        font.family: Config.Theme.fontFamily
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }

                }
            }

            Widgets.LabelButton {
                id: advancedButton
                Layout.fillWidth: true
                text: "Opções avançadas · pavucontrol"
                implicitHeight: 38
                labelFontSize: Config.Theme.fontSizeSmall
                idleTextColor: Config.Theme.colFg
                hoverTextColor: Config.Theme.colHighlight
                idleBackgroundColor: Config.Colors.md3.surface_container_highest
                hoverBackgroundColor: Qt.rgba(
                    Config.Theme.colHighlight.r, Config.Theme.colHighlight.g,
                    Config.Theme.colHighlight.b, 0.16
                )
                cornerRadius: 9
                activeFocusOnTab: true
                Accessible.name: "Abrir opções avançadas de áudio no pavucontrol"
                onClicked: {
                    root.closeMenu()
                    Quickshell.execDetached(["pavucontrol"])
                }
            }
        }
    }
}
