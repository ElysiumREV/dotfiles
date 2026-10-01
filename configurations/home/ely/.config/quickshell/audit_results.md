# Auditoria de Código - Quickshell Configuration

Este documento lista redundâncias, problemas potenciais e sugestões de melhoria identificadas no diretório `/home/ely/.config/quickshell`.

## 🔴 Redundâncias Críticas (Duplicação de Lógica)

### 1. Lógica de Ícones e Cores de Bateria
A lógica para determinar qual ícone de bateria exibir e qual cor usar (baseado na porcentagem e no estado de carga) está duplicada em:
- `modules/Battery.qml`
- `modules/BatteryMenu.qml`

**Sugestão:** Centralizar essa lógica em um serviço (ex: `services/Battery.qml`) ou criar um helper para que ambos os módulos consumam a mesma regra de negócio.

### 2. Estrutura de OSD (On-Screen Display)
Os arquivos `widgets/VolumeOSD.qml` e `widgets/BrightnessOSD.qml` são virtualmente idênticos em sua estrutura de UI (PanelWindow $\rightarrow$ Rectangle $\rightarrow$ RowLayout $\rightarrow$ Texto/Ícone/Barra).

**Sugestão:** Criar um componente genérico `widgets/OSD.qml` que aceite propriedades como `value`, `icon`, `label` e `color`, reduzindo drasticamente a quantidade de código repetido.

### 3. Ações de Sessão (Lock/Logout/Reboot/Shutdown)
A lógica de `requestAction` e `confirmAction` (incluindo as chamadas de shell para `hyprlock`, `hyprctl`, `systemctl`) está duplicada em:
- `modules/ArchMenu.qml`
- `modules/BatteryMenu.qml`

**Sugestão:** Mover essas funções para um serviço global (ex: `services/Session.qml`) para evitar a manutenção de múltiplos pontos de chamada de sistema.

---

## 🟡 Problemas Potenciais e Melhorias de Arquitetura

### 1. "Magic Numbers" e Estilização Repetitiva na Barra
Em `modules/Bar.qml`, diversos containers de módulos (Rectangles) utilizam as mesmas propriedades fixas:
- `height: 28`
- `radius: 10`
- `color: Qt.rgba(Config.Theme.colTextSec.r, Config.Theme.colTextSec.g, Config.Theme.colTextSec.b, 0.12)`

**Sugestão:** Mover esses valores para o `Theme.qml` ou criar um componente `ModuleContainer.qml` para padronizar a aparência dos grupos da barra.

### 2. Polling de Processos Shell
O projeto faz uso extensivo de `Process` para ler informações do sistema:
- `modules/SystemStatus.qml`: Lê `/proc/stat` e `free` a cada 2 segundos.
- `modules/BatteryMenu.qml`: Executa um comando complexo de `busctl` para ciclos de carga.
- `modules/ArchMenu.qml`: Executa `nmcli` e `bluetoothctl` repetidamente.

**Sugestão:** Verificar se existem APIs nativas do Quickshell ou serviços de sistema (via DBus) que forneçam essas informações de forma reativa (via sinais) em vez de polling, o que reduziria o uso de CPU e a latência.

### 3. Inconsistência de Fontes de Ícones
O projeto alterna entre "Material Symbols Rounded" e "JetBrainsMono Nerd Font" (ícones Nerd Font) em diferentes módulos (ex: `modules/Brightness.qml` vs `modules/Media.qml`).

**Sugestão:** Padronizar a biblioteca de ícones para manter a consistência visual em toda a interface.

---

## 🟢 Ajustes Finos e Simplificações (Clean Code)

### 1. Simplificação de Cores no Relógio
Em `modules/Clock.qml`, a cor de três elementos diferentes é definida por ternários idênticos baseados em `calendarMouse.containsMouse`.

**Sugestão:** Definir uma propriedade `readonly property color accentColor: calendarMouse.containsMouse ? Config.Theme.colHighlight : Config.Theme.colFg` e usá-la nos três elementos.

### 2. Posicionamento de Menus Popup
O `positionProvider` do `ArchMenu` em `modules/Bar.qml` é mais simples que o do `BatteryMenu`. Enquanto o `BatteryMenu` previne que o popup saia da tela à direita, o `ArchMenu` não faz isso, o que pode causar cortes na interface em telas menores ou resoluções específicas.

**Sugestão:** Padronizar a lógica de "clamping" (limite de borda) para todos os popups da barra.

### 3. Otimização de Processos no ArchMenu
O `ArchMenu.qml` dispara múltiplos processos de refresh (`wifiStatusProcess`, `wifiNameProcess`, `bluetoothStatusProcess`, etc.) quase simultaneamente ao abrir.

**Sugestão:** Agrupar algumas dessas leituras em scripts menores ou usar um único processo que retorne um JSON/CSV com todas as informações necessárias.
