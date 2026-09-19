import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".." as Config

Variants {
	id: root

	property color backgroundColor: Config.Theme.colWlogoutBg
	property color buttonColor: Config.Theme.colWlogoutButton
	property color buttonHoverColor: Config.Theme.colWlogoutButtonHover
	property color textColor: Config.Theme.colWlogoutText
	property color borderColor: Config.Theme.colBorder
	property real gridScale: Config.Theme.wlogoutGridScale
	property real iconScale: Config.Theme.wlogoutIconScale
	property int textMargin: Config.Theme.wlogoutTextTopMargin
	property int textSize: Config.Theme.wlogoutTextSize
	property int borderWidth: Config.Theme.wlogoutBorderWidth

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
				z: 0

				MouseArea {
					anchors.fill: parent
					onClicked: Qt.quit()
				}
			}

			Grid {
				id: buttonGrid
				anchors.centerIn: parent
				width: parent.width * root.gridScale
				height: parent.height * root.gridScale
				z: 1
				columns: 3

				Repeater {
					model: root.buttons

				delegate: Rectangle {
					required property LogoutButton modelData
					width: buttonGrid.width / buttonGrid.columns
					height: buttonGrid.height / Math.ceil(root.buttons.length / buttonGrid.columns)

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
