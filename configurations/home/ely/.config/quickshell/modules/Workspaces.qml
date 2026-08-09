  import Quickshell
  import Quickshell.Hyprland
  import QtQuick
  import ".." as Config

  Item {
      id: root

      property int workspaceCount: 10
      property real buttonSize: 26
      property real spacing: 4

      readonly property var monitor:
          Hyprland.monitorFor(root.QsWindow.window?.screen)

      readonly property int activeIndex: {
          const id = monitor?.activeWorkspace?.id ?? -1;
          return id >= 1 && id <= workspaceCount ? id - 1 : -1;
      }

      implicitWidth: strip.width
      implicitHeight: Config.Theme.moduleHeight

      Item {
            id: strip
            anchors.centerIn: parent

            width: root.workspaceCount * root.buttonSize
                   + (root.workspaceCount - 1) * root.spacing
            height: root.buttonSize

            Rectangle {
                id: activeIndicator
                z: 1

                x: Math.max(0, root.activeIndex)
                   * (root.buttonSize + root.spacing)
                y: 0

                width: root.buttonSize
                height: root.buttonSize
                radius: width / 2
                color: Config.Theme.colHighlight

                Behavior on x {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

      Repeater {
              model: root.workspaceCount

              delegate: Item {
                  id: workspaceItem

                  required property int index
                  readonly property int workspaceId: index + 1

                  // `workspace` será null quando o espaço ainda não foi criado.
                  readonly property var workspace:
                      Hyprland.workspaces.values.find(
                          item => item.id === workspaceId
                      )

                  // Escolha simples: a última janela da lista representa o workspace.
                  readonly property var toplevels:
                      workspace?.toplevels.values ?? []

                  readonly property var mainToplevel:
                      toplevels.length > 0
                      ? toplevels[toplevels.length - 1]
                      : null

                  readonly property string appId:
                      mainToplevel?.wayland?.appId ?? ""

                  readonly property bool occupied: toplevels.length > 0
                  readonly property bool active:
                      root.activeIndex === index
                  readonly property bool showUrgency:
                      (workspace?.urgent ?? false) && !(workspace?.focused ?? false)

                  x: index * (root.buttonSize + root.spacing)
                  y: 0
                  width: root.buttonSize
                  height: root.buttonSize
                  z: 2

                  // Camada 2: fundo discreto de workspace ocupado.
                  Rectangle {
                      anchors.centerIn: parent
                      width: root.buttonSize
                      height: root.buttonSize
                      radius: width / 2
                      color: Config.Theme.colTextSec
                      opacity: workspaceItem.occupied
                               && !workspaceItem.active ? 0.13 : 0

                      Behavior on opacity {
                          NumberAnimation { duration: 160 }
                      }
                  }

                  // Camada 3: hover.
                  Rectangle {
                      anchors.centerIn: parent
                      width: root.buttonSize
                      height: root.buttonSize
                      radius: width / 2
                      color: Config.Theme.colText
                      opacity: mouseArea.containsMouse
                               && !workspaceItem.active ? 0.10 : 0

                      Behavior on opacity {
                          NumberAnimation { duration: 120 }
                      }
                  }

                  // Camada 4: ícone do aplicativo principal.
                  Image {
                      id: appIcon
                      anchors.centerIn: parent
                      width: 22
                      height: 22
                      sourceSize.width: width * 2
                      sourceSize.height: height * 2
                      asynchronous: true
                      smooth: true

                      // O fallback evita um ícone quebrado para apps sem desktop entry.
                      source: workspaceItem.appId
                          ? Quickshell.iconPath(
                              workspaceItem.appId,
                              "application-x-executable"
                          )
                          : ""

                      opacity: workspaceItem.occupied ? 1 : 0
                      scale: workspaceItem.active ? 1 : 0.82

                      Behavior on opacity {
                          NumberAnimation { duration: 160 }
                      }

                      Behavior on scale {
                          NumberAnimation {
                              duration: 180
                              easing.type: Easing.OutCubic
                          }
                      }
                  }

                  // Mostra numeral romano apenas se o workspace estiver vazio.
                  Text {
                      anchors.centerIn: parent
                      visible: !workspaceItem.occupied
                      text: root.toRoman(workspaceItem.workspaceId)
                      color: workspaceItem.active
                             ? Config.Theme.colBg
                             : Config.Theme.colDisabled
                      font {
                          family: Config.Theme.fontFamily
                          pixelSize: 12
                          bold: true
                      }

                      Behavior on color {
                          ColorAnimation { duration: 160 }
                      }
                  }

                  Rectangle {
                      id: urgencyFlash
                      anchors.centerIn: parent
                      width: root.buttonSize - 2
                      height: root.buttonSize - 2
                      radius: width / 2
                      color: "transparent"
                      border.width: 2
                      border.color: Config.Theme.colRed
                      opacity: 0
                      z: 10
                  }

                  SequentialAnimation {
                      running: workspaceItem.showUrgency
                      loops: Animation.Infinite

                      NumberAnimation {
                          target: urgencyFlash
                          property: "opacity"
                          from: 0
                          to: 1
                          duration: 180
                      }
                      PauseAnimation { duration: 420 }
                      NumberAnimation {
                          target: urgencyFlash
                          property: "opacity"
                          to: 0
                          duration: 300
                      }
                      PauseAnimation { duration: 300 }
                  }

                  MouseArea {
                      id: mouseArea
                      anchors.fill: parent
                      anchors.margins: -3
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor

                      onClicked: {
                          // Também cria/foca um workspace ainda inexistente.
                          Hyprland.dispatch(
                              Hyprland.usingLua
                              ? `hl.dsp.focus({ workspace = ${workspaceItem.workspaceId} })`
                              : "workspace " + workspaceItem.workspaceId
                          )
                      }

                      onWheel: event => {
                          Hyprland.dispatch(
                              Hyprland.usingLua
                              ? event.angleDelta.y < 0
                                ? 'hl.dsp.focus({ workspace = "r+1" })'
                                : 'hl.dsp.focus({ workspace = "r-1" })'
                              : event.angleDelta.y < 0
                                ? "workspace r+1"
                                : "workspace r-1"
                          )
                      }
                  }
              }
          }
      }

      function toRoman(num) {
          const values = [
              "", "I", "II", "III", "IV",
              "V", "VI", "VII", "VIII", "IX", "X"
          ];
          return values[num] ?? num;
      }
  }
