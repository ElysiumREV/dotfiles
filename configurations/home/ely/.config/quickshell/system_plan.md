# Plano geral do Quickshell

Documento central para o roadmap, notificações, auditoria técnica/visual e dependências desta configuração. Atualizado em **2026-10-07**. A meta é fazer do Quickshell o centro de interação e controle do desktop, mantendo Hyprland e os serviços especializados como backends.

## Visão e limites

Quickshell deve concentrar a interface diária: barra, menus, launcher, notificações, seletores e controles rápidos. Não precisa substituir o compositor, os serviços de rede/áudio/energia, nem aplicativos especializados.

- Hyprland continua responsável pela sessão, janelas, workspaces e regras do compositor.
- NetworkManager, BlueZ, PipeWire, UPower e serviços equivalentes continuam realizando o trabalho de sistema.
- Manter `hyprlock` para bloquear a sessão até que uma solução própria tenha autenticação e comportamento de segurança comprovados.
- Abrir um gerenciador de arquivos instalado em vez de criar um dentro da shell.
- Recursos opcionais devem falhar com estado/mensagem claros se suas dependências não estiverem instaladas.

## O que já existe

- Barra, workspaces, bandeja, relógio, mídia e indicadores de sistema.
- Application Launcher com busca e histórico de uso.
- Seletor de wallpapers local e Wallhaven, aplicação via `swww`/`awww` e geração de paleta com Matugen.
- Controles de volume, brilho, bateria e perfis de energia.
- Arch Menu com controles de Wi-Fi e Bluetooth e ações de sessão.
- Popups de notificação, Notification Center, indicador na barra e IPC.
- Wlogout e comandos IPC para abrir recursos da shell.

## Roadmap

### Prioridade 1 — concluir a validação das notificações

O serviço, os popups, o centro, o indicador e o IPC já estão implementados. Em 2026-10-07, o Quickshell assumiu `org.freedesktop.Notifications`; `notify-send` retornou sucesso e o usuário confirmou que viu o popup. A linha de inicialização do Mako está comentada no autostart.

Estado e comportamento atuais:

- Histórico limitado a 50 entradas e mantido em memória, sem gravar o texto das mensagens em disco.
- X do popup arquiva a notificação como lida no centro; X dentro do centro remove o item do histórico.
- Timeout positivo informado pelo aplicativo é respeitado; timeout ausente ou zero usa três segundos.
- Até cinco popups aparecem ao mesmo tempo.
- Ações do aplicativo são suportadas enquanto a notificação permanece ativa. Resposta inline não é anunciada como suportada.
- Imagens aparecem nos popups e não ficam retidas no histórico.
- Não Perturbe suprime popups, mas preserva as notificações no centro.
- IPC: `shell toggleNotificationCenter`.

Validação manual que ainda vale fazer: imagens, botões de ação, urgências, timeouts solicitados pelos aplicativos, Não Perturbe, arquivar/remover, limpeza do histórico, reload e uso em múltiplos monitores. Não iniciar Mako junto com o servidor do Quickshell, pois ambos disputam o nome D-Bus. Rollback: desativar o servidor de notificações do Quickshell antes de reativar Mako.

Referências da API: [NotificationServer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/) e [Notification](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/Notification/).

### Prioridade 2 — evoluir o Arch Menu

- Adicionar seleção de saída/entrada de áudio, controles por dispositivo e microfone.
- Adicionar configurações avançadas da conexão: DNS personalizado para IPv4 e IPv6, com opção de voltar ao DNS automático fornecido pela rede. Considerar também exibir o método/endereço atual e validar os valores antes de aplicar.
- Revisar navegação por teclado, estados indisponíveis, erros e layouts em telas menores.
- Dividir `modules/ArchMenu.qml` em UI/serviços de Wi-Fi, Bluetooth e ações de sessão, preservando o comportamento em cada etapa.
- O menu usa as APIs Networking/Bluetooth do Quickshell para estado e descoberta; operações Bluetooth também chamam `bluetoothctl`. NetworkManager e BlueZ permanecem como serviços.
- Para edição dos perfis DNS do NetworkManager, avaliar `nmcli` ou uma API equivalente. O código atual não depende de `nmcli`; se escolhido, ele será uma dependência nova para esta função.
- Depois da separação, prototipar APIs nativas para reduzir parsing/polling somente se a cobertura funcional permanecer equivalente.

### Prioridade 3 — clipboard no launcher

Adicionar busca e reuso do histórico usando `cliphist` e `wl-clipboard` como ferramentas externas. Antes de implementar, definir retenção e tratamento de conteúdo sensível. O launcher será a interface, sem criar um daemon de clipboard próprio.

### Prioridade 4 — configurações da shell

Criar uma tela para opções atualmente fixas/distribuídas: duração de notificações, preferências do launcher, diretório de wallpapers, comportamento da barra e atalhos. Persistir preferências em formato simples e fornecer defaults seguros para instalação nova.

### Prioridade 5 — captura e gravação de tela

Criar uma interface para selecionar tela/região e iniciar captura/gravação por ferramentas Wayland externas. `grim` e `slurp` são candidatos para captura; escolher a ferramenta de gravação e formatos antes de fechar dependências.

## Auditoria técnica e visual

Leitura estática de `Theme.qml`, `Colors.qml`, `shell.qml`, módulos e widgets em **2026-10-06**, considerando Quickshell 0.3.1. Não foram feitas medições de CPU/RAM nem validação completa de runtime. Os ganhos citados são estimativas, não medições.

### Ações de manutenção que valem considerar

1. **Validar resoluções e múltiplos monitores.** A barra posiciona grupos esquerdo, central e direito de forma independente; mídia pode ocupar até 350 px. Há risco de colisões em telas estreitas ou bandejas grandes, mas a leitura estática não confirma colisão em resolução específica. Alguns popups têm tamanho fixo e abrem abaixo da barra; Arch Menu tem lista Wi-Fi limitada/rolável, mas a lista Bluetooth e o painel total podem precisar de limites. Validar na tela menor e só então compactar, limitar altura/rolagem ou reposicionar para cima.
2. **Reduzir polling do brilho.** `services/Brightness.qml` consulta sysfs por processo a cada 200 ms. Considerar 500 ms–1 s e conferir a resposta às teclas Fn; benefício esperado é modesto, com possível pequeno atraso visual.
3. **Separar `ArchMenu.qml`.** O arquivo é muito grande e combina UI, estado e operações. Extrair por responsabilidade deve melhorar manutenção; não se espera ganho de runtime só pela divisão.
4. **Revisar idioma.** A maior parte da UI é português, mas Wallhaven e System Usage ainda têm textos em inglês. Uniformizar em português; adicionar localização configurável só se houver intenção de suportar idiomas diferentes.
5. **Documentar famílias de ícones.** A configuração usa JetBrainsMono Nerd Font e Material Symbols Rounded. Ambas são dependências visuais atuais; centralizar tamanhos recorrentes no tema e declarar `font.family` onde hoje depende da fonte padrão.
6. **Centralizar tokens visuais recorrentes.** Raios, bordas, scrim e fundos de legenda aparecem como literais em launcher, seletores, Arch Menu e popups. Adicionar tokens semânticos para superfícies/campos quando esses arquivos forem editados; não transformar todo espaçamento isolado em token.
7. **Rever carregamento de cores do Wlogout.** A instância do `shell.qml` usa `Theme.qml`, enquanto o modo standalone de `widgets/Wlogout.qml` mantém FileView/JsonAdapter e fallback próprios. Considerar helper compartilhado se o fluxo permitir; manter as duas fontes sincronizadas até lá.
8. **Avaliar cache do Wallhaven apenas se necessário.** O cache de JSON dura enquanto o seletor está aberto e é limpo ao fechar ou iniciar outra busca. Limitar páginas próximas só se sessões longas mostrarem consumo relevante.

### Melhorias de baixo impacto ou adiáveis

- Extrair layout comum entre `VolumeOSD.qml` e `BrightnessOSD.qml` se esses widgets receberem mudanças visuais; os gatilhos continuam separados e o ganho é de manutenção, não de desempenho.
- `PowerProfiles.qml` consulta `powerprofilesctl` a cada 30 s. A API `UPower.PowerProfiles` pode ser avaliada se representar corretamente estado indisponível; o polling atual é baixo.
- Não há evidência para reescrever o launcher em C++: o catálogo observado tinha cerca de 92 `.desktop`, a busca opera numa lista limitada e a exibição usa `ListView`.
- Não há evidência de pressão de RAM pelo histórico do launcher, que guarda contagem e último uso por app.
- Evitar agrupar comandos de rede num processo só; isso aumenta acoplamento do parsing.
- Não centralizar ações de sessão até definir uma semântica comum entre Arch Menu e Battery Menu.
- Unificar OSDs não é uma otimização de performance.

### Observações de consistência já resolvidas ou sem ação necessária

- Regras de ícone/estado de bateria estão em `services/BatteryRules.js`.
- Cor de destaque do relógio é centralizada em `accentColor`.
- `modules/ModuleGroup.qml` fornece a moldura compartilhada da barra.
- Os popups relevantes recebem provedores de posição.
- Métricas de CPU/memória leem `/proc/stat` e `/proc/meminfo` a cada cinco segundos; não há indicação de que isso deva ser priorizado.
- Launcher, seletor local e Wallhaven compartilham tema, mas têm dimensões diferentes de acordo com o conteúdo. O Wlogout também tem composição própria intencional.
- Wallhaven usa `hyprctl -j monitors` para filtrar por resolução, mas baixa o arquivo original da API; não redimensiona localmente.

## Dependências

Inventário baseado nos comandos/imports atuais. “Obrigatória” significa necessária para a feature correspondente, não necessariamente para carregar todas as partes da shell. Serviços e pacotes variam por distribuição.

### Base e sessão

| Dependência | Usada por | Estado |
| --- | --- | --- |
| Quickshell 0.3.1 com módulos QML usados: Hyprland, Wayland, Networking, Bluetooth, PipeWire, MPRIS e UPower | Shell inteira | Obrigatória; build sem algum módulo importado pode falhar ao carregar. |
| Hyprland e `hyprctl` | Workspaces, monitores, IPC e Wallhaven | Obrigatórios nesta configuração. |
| D-Bus de sessão | Notificações, tray e integrações | Obrigatório. |
| JetBrainsMono Nerd Font e Material Symbols Rounded | Texto/ícones | Necessárias para aparência e ligaduras esperadas. |
| Aplicativos com arquivos `.desktop` | Launcher | Cada aplicativo precisa de uma entrada para aparecer corretamente. |

### Serviços e ferramentas

| Dependência | Usada por | Estado |
| --- | --- | --- |
| NetworkManager ativo | Wi-Fi no Arch Menu via Quickshell Networking | Necessário para Wi-Fi. |
| BlueZ (`bluetoothd`) e `bluetoothctl` | Estado, descoberta, pareamento e operações Bluetooth | Necessários para Bluetooth. |
| PipeWire e gerenciador de sessão (normalmente WirePlumber) | Controles de áudio | Necessários para áudio. |
| Player MPRIS compatível | Módulo Media | Opcional; necessário para controles de mídia úteis. |
| UPower e `upower` | Bateria e consulta de propriedades | Necessários para bateria; algumas métricas dependem do hardware. |
| `busctl` | Saúde/ciclos no Battery Menu | Necessário para essas consultas extras. |
| `power-profiles-daemon` e `powerprofilesctl` | Perfis de energia | Opcionais; o menu verifica disponibilidade. |
| `brightnessctl` | Alterar brilho | Necessário em hardware com backlight compatível; conferir permissões. |
| `curl` | Busca/download Wallhaven | Necessário para Wallhaven. |
| `swww` ou `awww` | Aplicar wallpapers | Um deles é necessário e seu daemon deve iniciar na sessão. O código tenta `swww` e depois `awww`. |
| Matugen e `~/.config/scripts/updateWall.sh` | Atualização de paleta após wallpaper | Necessários para o fluxo atual. O script é externo ao projeto e precisa ser instalado/documentado numa máquina nova. |
| `hyprlock` | Bloqueio de sessão | Necessário para Lock. |
| `hyprshutdown` | Wlogout e comandos de sessão | Necessário para fluxo Wlogout atual. |
| `systemctl`, `shutdown`, `reboot` | Energia e sessão | Necessários para as ações correspondentes; ambiente atual usa systemd. |
| `find`, `mkdir`, `ln`, `sh`, `bash`, `awk`, `cat`, `which` | Wallpapers, queries e helpers | Ferramentas padrão esperadas no ambiente Arch/base. |
| Mako ou outro daemon de notificação | Nenhum no modo atual | Não iniciar junto com o Quickshell; disputa `org.freedesktop.Notifications`. `notify-send` é útil para validação, não requisito de runtime. |

### Dependências planejadas

| Implementação | Dependências candidatas | Observações |
| --- | --- | --- |
| Clipboard no launcher | `cliphist`, `wl-clipboard` | Definir política de retenção e conteúdo sensível. |
| Configurações DNS IPv4/IPv6 no Arch Menu | NetworkManager; possivelmente `nmcli` | Planejada. Permitir DNS manual e retorno ao modo automático sem quebrar perfis já existentes. |
| Captura de tela | `grim`, `slurp` | Confirmar seleção de região/tela na sessão. |
| Gravação de tela | A escolher | Selecionar ferramenta e formatos antes de adicionar à instalação. |

## Checklist para instalação nova

1. Instalar uma build do Quickshell que inclua os módulos listados e iniciar a sessão D-Bus/Hyprland corretamente.
2. Instalar/iniciar NetworkManager, BlueZ, PipeWire + gerenciador de sessão e UPower conforme as features desejadas.
3. Instalar fontes JetBrainsMono Nerd Font e Material Symbols Rounded.
4. Escolher `swww` ou `awww`, iniciar seu daemon e instalar Matugen.
5. Incluir `~/.config/scripts/updateWall.sh` ou migrá-lo para dentro deste projeto; confirmar sua chamada ao Matugen.
6. Instalar os opcionais de hardware/sessão que serão usados: `brightnessctl`, `power-profiles-daemon`, `hyprlock`, `hyprshutdown`.
7. Garantir que só um daemon de notificações esteja ativo.
8. Criar um manifesto específico do Arch separando obrigatório, opcional e planejado. Este documento é inventário, não instalador.

## Ordem de execução consolidada

1. Validar fluxos pendentes de notificações e instalação/daemon.
2. Conferir layouts na menor resolução e uniformizar textos/fontes conforme necessário.
3. Polir o Arch Menu, adicionar controles de áudio e extrair componentes gradualmente.
4. Reduzir polling do brilho e observar responsividade.
5. Integrar clipboard ao launcher.
6. Criar configurações persistentes da shell.
7. Avaliar captura/gravação, API nativa para Wi-Fi/Bluetooth e demais refatorações quando houver benefício observado.
