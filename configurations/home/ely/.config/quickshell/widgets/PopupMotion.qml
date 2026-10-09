import QtQuick
import ".." as Config

// Animação compartilhada de entrada/saída dos popups e overlays.
//
// Dois canais de progresso:
//   progress    -> opacidade e deslocamento, curva sem overshoot
//   popProgress -> só o scale, com overshoot controlado (ver Theme.easePop)
//
// A superfície deve:
//   1. implementar close() chamando requestClose()
//   2. esconder a janela em onExitFinished() (porque `visible` pode ser binding
//      nos overlays ligados ao WindowControl, e escrever nele quebraria o binding)
QtObject {
    id: root

    required property var popup

    // Emitido quando a animação de saída termina; a superfície esconde a janela aqui.
    signal exitFinished()

    property real progress: 0
    property real popProgress: 0

    readonly property bool closing: internalClosing
    property bool internalClosing: false

    // Valores iniciais do card.
    property real startScale: 0.96
    property real startOffset: -8

    // Overlays de tela cheia pedem mais tempo que popups ancorados na barra.
    property int inDuration: Config.Theme.durPopupIn
    property int outDuration: Config.Theme.durPopupOut

    readonly property real contentOpacity: progress
    readonly property real contentScale: startScale + (1 - startScale) * popProgress
    readonly property real contentOffsetY: startOffset * (1 - progress)

    // Animação de entrada. Assumir a janela já visível: quem abre decide como.
    function playIn() {
        internalClosing = false;
        closeOpacity.stop();
        closePop.stop();
        enterOpacity.restart();
        enterPop.restart();
    }

    // Animação de saída. Idempotente.
    function requestClose() {
        if (internalClosing) return;
        internalClosing = true;
        enterOpacity.stop();
        enterPop.stop();
        closeOpacity.restart();
        closePop.restart();
    }

    // Reentrada do ponteiro durante a saída: volta ao aberto.
    function cancelClose() {
        if (!internalClosing) return;
        internalClosing = false;
        closeOpacity.stop();
        closePop.stop();
        enterOpacity.restart();
        enterPop.restart();
    }

    // Janela escondida por outro caminho: zerar sem animar.
    function reset() {
        internalClosing = false;
        enterOpacity.stop();
        enterPop.stop();
        closeOpacity.stop();
        closePop.stop();
        progress = 0;
        popProgress = 0;
    }

    NumberAnimation {
        id: enterOpacity
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Config.Theme.motionDur(root.inDuration)
        easing.type: Config.Theme.easeOut
    }

    NumberAnimation {
        id: enterPop
        target: root
        property: "popProgress"
        from: 0
        to: 1
        duration: Config.Theme.motionDur(root.inDuration)
        easing.type: Config.Theme.easePop
    }

    NumberAnimation {
        id: closeOpacity
        target: root
        property: "progress"
        from: root.progress
        to: 0
        duration: Config.Theme.motionDur(root.outDuration)
        easing.type: Config.Theme.easeIn
        onFinished: {
            if (!root.internalClosing) return;
            root.internalClosing = false;
            root.progress = 0;
            root.popProgress = 0;
            root.exitFinished();
        }
    }

    NumberAnimation {
        id: closePop
        target: root
        property: "popProgress"
        from: root.popProgress
        to: 0
        duration: Config.Theme.motionDur(root.outDuration)
        easing.type: Config.Theme.easeIn
    }
}
