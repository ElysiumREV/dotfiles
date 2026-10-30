import QtQuick
import QtQuick.Layouts
import ".." as Config

Rectangle {
    id: root

    required property string title
    required property string iconName
    required property string value
    property real progress: 0
    property bool muted: false

    radius: 20
    color: Config.Theme.colOsdBg
    border.width: Config.Theme.osdBorderWidth
    border.color: Config.Theme.colOsdBorder

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: Config.Theme.osdSpacing

        Rectangle {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            Layout.alignment: Qt.AlignVCenter
            radius: 16
            color: root.muted ? Config.Colors.md3.surface_container_highest
                              : Config.Colors.md3.primary_container

            Text {
                anchors.centerIn: parent
                text: root.iconName
                color: root.muted ? Config.Colors.md3.on_surface_variant
                                  : Config.Colors.md3.on_primary_container
                font.family: "Material Symbols Rounded"
                font.pixelSize: Config.Theme.osdIconSize
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Config.Theme.colTextSec
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeSmall
                    elide: Text.ElideRight
                }

                Text {
                    text: root.value
                    color: root.muted ? Config.Theme.colTextSec : Config.Theme.colFg
                    font.family: Config.Theme.fontFamily
                    font.pixelSize: Config.Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                id: progressTrack
                Layout.fillWidth: true
                Layout.preferredHeight: Config.Theme.osdBarHeight
                radius: Config.Theme.osdBarRadius
                color: Config.Colors.md3.surface_container_highest
                clip: true

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(1, root.progress))
                    radius: parent.radius
                    color: root.muted ? Config.Theme.colOsdMuted : Config.Theme.colHighlight

                    Behavior on width {
                        NumberAnimation {
                            duration: Config.Theme.motionFast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Theme.curveSpatialFast
                        }
                    }
                }
            }
        }
    }
}
