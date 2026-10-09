import QtQuick
import Config

Item {
    id: root
    
    property bool active: false
    anchors.fill: parent

    Item {
        id: container
        anchors.fill: parent
        
        // Opacidade suave
        opacity: root.active ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { 
                duration: Config.Theme.menuAnimDuration
                easing.type: Config.Theme.menuAnimEasing 
            }
        }

        // Escala sutil para dar profundidade
        scale: root.active ? 1.0 : 0.98
        Behavior on scale {
            NumberAnimation { 
                duration: Config.Theme.menuAnimDuration
                easing.type: Config.Theme.menuAnimEasing 
            }
        }

        // Efeito de "descer da barra": começa acima (-20px) e desce para 0
        y: root.active ? 0 : -20
        Behavior on y {
            NumberAnimation { 
                duration: Config.Theme.menuAnimDuration
                easing.type: Config.Theme.menuAnimEasing 
            }
        }
        
        default property alias content: data
    }
}
