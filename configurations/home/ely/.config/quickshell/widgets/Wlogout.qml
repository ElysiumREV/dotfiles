import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
	id: root

	property color backgroundColor: "#e60c0c0c"
	property color buttonColor: "#1e1e1e"
	property color buttonHoverColor: "#3700b3"
	property color textColor: "white"
	property color borderColor: "black"
	property real gridScale: 0.75
	property real iconScale: 0.25
	property int textMargin: 20
	property int textSize: 20
	property int borderWidth: 1

	default property list<LogoutButton> buttons

	model: Quickshell.screens

	delegate: Component {
		PanelWindow {
			id: w

			required property var modelData
			screen: modelData

			exclusionMode: ExclusionMode.Ignore
			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

			color: "transparent"

			anchors {
				top: true
				left: true
				bottom: true
				right: true
			}

			contentItem {
				focus: true

				Keys.onPressed: event => {
					if (event.key === Qt.Key_Escape) {
						Qt.quit();
						return;
					}

					for (let i = 0; i < root.buttons.length; i++) {
						const button = root.buttons[i];
						if (event.key === button.keybind) {
							button.exec();
							return;
						}
					}
				}
			}

			Rectangle {
				anchors.fill: parent
				color: root.backgroundColor

				MouseArea {
					anchors.fill: parent
					onClicked: Qt.quit()

					GridLayout {
						anchors.centerIn: parent
						width: parent.width * root.gridScale
						height: parent.height * root.gridScale

						columns: 3
						columnSpacing: 0
						rowSpacing: 0

						Repeater {
							model: root.buttons

							delegate: Rectangle {
								required property LogoutButton modelData

								Layout.fillWidth: true
								Layout.fillHeight: true

								color: mouseArea.containsMouse ? root.buttonHoverColor : root.buttonColor
								border.color: root.borderColor
								border.width: mouseArea.containsMouse ? 0 : root.borderWidth

								MouseArea {
									id: mouseArea

									anchors.fill: parent
									hoverEnabled: true
									onClicked: modelData.exec()
								}

								Image {
									id: icon

									anchors.centerIn: parent
									source: Qt.resolvedUrl("icons/" + modelData.icon + ".png")
									width: parent.width * root.iconScale
									height: width
									fillMode: Image.PreserveAspectFit
									smooth: true
								}

								Text {
									anchors {
										top: icon.bottom
										topMargin: root.textMargin
										horizontalCenter: parent.horizontalCenter
									}

									text: modelData.text
									font.pointSize: root.textSize
									color: root.textColor
								}
							}
						}
					}
				}
			}
		}
	}
}
