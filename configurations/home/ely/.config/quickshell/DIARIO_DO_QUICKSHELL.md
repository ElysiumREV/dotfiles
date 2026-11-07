# Diário de ideias e decisões do Quickshell

Este é o documento canônico de contexto, decisões, roadmap e auditorias deste projeto. Atualizar este arquivo quando uma feature mudar de estado, uma preferência visual for decidida ou uma ideia nova surgir. Ao retomar trabalho, consultar primeiro **Estado atual**, **Decisões persistentes** e **Roadmap**; o apêndice preserva os planos antigos para contexto histórico.

Última consolidação: 2026-11-06.

## Visão do projeto

O Quickshell deve concentrar a interface diária do desktop: barra, menus, launcher, notificações, seletores e controles rápidos. Hyprland e os serviços especializados continuam responsáveis pelo trabalho de sistema.

- Hyprland cuida da sessão, janelas, workspaces e regras do compositor.
- NetworkManager, BlueZ, PipeWire, UPower e serviços equivalentes continuam realizando as operações de sistema.
- Manter `hyprlock` para bloquear a sessão até que uma solução própria tenha autenticação e comportamento de segurança comprovados.
- Abrir um gerenciador de arquivos instalado em vez de criar um dentro da shell.
- Recursos opcionais devem falhar com estado/mensagem claros se suas dependências não estiverem instaladas.
- Otimizar CPU e memória: menus sob demanda, imagens com tamanho assíncrono, timers só enquanto úteis, eventos em vez de polling quando houver API adequada.

## Decisões e preferências persistentes

- Recursos acionados por keybind precisam funcionar integralmente com teclado; mouse é complementar.
- Menus e pop-ups devem fechar quando perdem o foco, conforme o comportamento comum já usado no shell.
- Usar carregamento sob demanda em menus, pop-ups e conteúdo caro. Se houver animação de saída, manter o item carregado só até a animação terminar e descarregá-lo em seguida.
- Evitar polling contínuo. Preferir IPC/eventos; quando polling for inevitável, limitar intervalo e duração ao estado em que a informação é necessária.
- Manter histórico de clipboard apenas enquanto o QuickShell estiver rodando, com limites de quantidade e tamanho.
- Preservar o estado aberto/recolhido do calendário entre aberturas do painel durante a sessão.
- A identidade visual é Material 3 dinâmico via Matugen. Usar cores semânticas, superfícies em níveis e hierarquia consistente; não copiar diretamente uma linguagem visual incompatível.
- O grupo direito da barra deve ganhar fundo colorido no hover/foco/seleção, sem uma borda luminosa ao redor.
- Preferir soluções simples, nativas e locais. Não duplicar serviços ou armazenar dados persistentes sem benefício claro.
- A UI, logs e comentários do código são em inglês; este diário permanece em português e deve ser atualizado a cada mudança relevante (feature, decisão ou limpeza).

## Estado atual das features

### Implementadas

- Barra com workspaces, bandeja, relógio, mídia, status do sistema e indicador da aplicação focada.
- O serviço MPRIS reconhece Spotify, YouTube Music e Spotifast, e usa o player ativo para metadados e controles de reprodução.
- Application Launcher com busca aproximada, ranking por uso e navegação por teclado.
- Seletor de wallpaper local e Wallhaven, com aplicação via `swww`/`awww` e geração de paleta Matugen.
- Clipboard History pelo IPC/keybind, apenas em memória durante a sessão; até 50 itens, limite de 32.768 caracteres por item e 524.288 caracteres no total. Não usa `cliphist`.
- Painel de áudio: saída padrão, mute do microfone, indicadores de captura e mixer por aplicativo; `pavucontrol` fica disponível para opções avançadas.
- Indicadores de microfone e câmera. A detecção de captura acompanha conexões PipeWire sem polling; acessos diretos V4L2 podem não aparecer e não há mute genérico de câmera.
- Painel unificado de controles e notificações: Wi-Fi, Bluetooth, Não Perturbe, brilho, mídia, notificações, mixer de volume, bateria e calendário. Detalhes de redes e Bluetooth começam recolhidos; wlogout é aberto por um único botão.
- O grupo da direita da barra inclui volume, anel circular de nível da bateria sem percentual, Wi-Fi e Bluetooth. Clicar no anel abre a aba Bateria do painel unificado; nela aparecem estado/carga, autonomia, potência, saúde/ciclos quando disponíveis e seleção de perfis de energia. Os dados extras são consultados apenas enquanto a aba está carregada.
- Calendário recolhível, iniciado no domingo, com segundos atualizados enquanto o menu está aberto e estado recolhido/expandido guardado durante a sessão.
- Seleção de screenshot por região ou janela: `hyprshot --freeze` cuida do congelamento, seleção, salvamento em `Pictures/Screenshots` e cópia para o clipboard.
- Menus carregados por demanda por monitor; estado/posicionamento considera o monitor-alvo.
- Preferências da barra em `settings.json`, carregadas/salvas via `Preferences.qml`; a aba Configurações permite controlar aplicativo em foco, data, bandeja, indicadores de dispositivos, status do sistema e mídia.
- Central de atalhos rápidos no ArchMenu: bloquear com `hyprlock`, abrir ações de sessão, launcher, histórico do clipboard e abrir `pavucontrol`. `SUPER+O` abre a aba e `SUPER+N` alterna DND; ambos ficam configuráveis em `~/.config/hypr/modules/keybinds.lua` e aparecem no cheatsheet do Hyprland. O botão DND permanece nos controles rápidos e o indicador aparece na barra quando ativo.
- A preferência persistente `launcher.prioritizeUsage` controla se o uso recente desempata resultados do launcher; quando desativada, resultados de mesma relevância ficam em ordem alfabética.
- A pasta escolhida no seletor de wallpapers fica salva em `wallpaper.directory` e também é usada para downloads do Wallhaven; valor vazio mantém `~/Pictures/Wallpapers` como padrão.
- A duração padrão dos pop-ups de notificação é ajustável entre 1 e 10 segundos na aba Configurações; timeout informado pelo aplicativo tem precedência e zero continua significando sem expiração.
- Volume e brilho acionados por IPC conforme os atalhos existentes.
- Scripts necessários do projeto estão dentro do diretório do QuickShell (`scripts/`). O projeto não depende mais de `~/.config/scripts/updateWall.sh` (removido em 2026-11-06); `services/WallpaperManager.qml` chama `scripts/apply_colors.sh`. O `config.toml` do Matugen só gera arquivos (sem `post_hook`); todos os hooks (Kitty, GTK, KDE, Neovim, Pywalfox, Spotifast) ficam em `scripts/apply_colors.sh`, cada um opcional e com aviso em caso de falha. Gera também `~/.config/hypr/hyprlock-colors.conf`, incluído pelo `hyprlock.conf`.
- Wallpaper, Clipboard e Wallhaven foram alinhados visualmente ao Application Launcher: superfície flutuante Material, desktop visível, cantos e espaçamentos coerentes, destaque de foco e scrollbars temáticas. Quickshell recarregou sem erros QML aparentes em 2026-10-16.

### Em validação ou polimento

- Notificações: serviço, pop-ups, centro, indicador e IPC estão implementados. `notify-send` foi validado e o usuário confirmou que viu o pop-up. Ainda vale validar manualmente imagens, ações, urgências, timeouts, Não Perturbe, arquivar/remover, limpeza, reload e múltiplos monitores.
- Visual: conferir contraste com diferentes paletas Matugen e recorte/rolagem em resoluções baixas e em mais de um monitor. A recarga automática foi observada; a validação física depende de abrir os menus nessas condições.
- Painel unificado: revisar expansão de Wi-Fi/Bluetooth, navegação por teclado, estados indisponíveis e erros em telas menores.
- Mixer do Arch Menu: seleção de dispositivos, volume de saída e mute do microfone estão implementados; o usuário confirmou o botão de microfone na barra e o fallback dos dispositivos em 2026-10-26. Streams por aplicativo estão implementadas; ainda falta validar visualmente suas linhas e testar mute/volume no menu.
- Wi-Fi e Bluetooth: detalhes seguem recolhidos até abrir; redes Wi-Fi ficam ordenadas por conexão, salvas e intensidade. Bluetooth inicia descoberta temporária ao abrir os detalhes, encerra ao recolher/fechar e ordena conectados, pareados e disponíveis, priorizando nomes legíveis. O botão agora detecta estado `Blocked` e tenta `rfkill unblock bluetooth` antes de ligar o adaptador. Requer `rfkill` além do `bluetoothctl` já listado; confirmar o comportamento na sessão, pois rfkill pode exigir permissões do sistema.
- Screenshot: seleção de região e janela via `hyprshot --freeze`; em 2026-10-26, o usuário confirmou que o fluxo funciona também em jogo fullscreen. O Quickshell deixa a seleção/salvamento/clipboard a cargo do utilitário externo.
- MPRIS/Spotifast: o serviço agora permite o player Spotifast pela identidade, entrada desktop ou nome de barramento MPRIS. Falta validar metadados, artwork, volume e comandos durante uma sessão ativa; a inspeção atual não conseguiu acessar o barramento D-Bus da sessão.
- Cheatsheet de atalhos: primeira versão implementada com `SUPER+H`; consulta `hyprctl binds -j` somente ao abrir, categoriza os atalhos e oferece busca por teclado, seleção da lista e fechamento por `Esc`. As binds ativas atuais receberam descrições curtas com categoria; novas binds devem seguir esse padrão. Falta validar o painel visualmente na sessão.
- Idioma: a UI, os logs, os comentários do código e as descrições dos atalhos do Hyprland passaram a ser **todos em inglês** (2026-11-06). Este diário continua em português por decisão do usuário. Novos textos de UI devem ser escritos em inglês.

### Ideias ainda em aberto

1. **Central de atalhos:** implementada e confirmada em uso; ações no ArchMenu e binds `SUPER+O`/`SUPER+N` funcionando.
2. **Busca ampliada no launcher:** avaliar busca de arquivos, ações e comandos. Definir dependências e custo de indexação antes de escolher estratégia; preservar busca sob demanda.
3. **Resumo de bateria/energia na barra:** usar informações que já estão disponíveis no menu da bateria, sem consultas adicionais contínuas.
4. **Perfis de contexto:** agrupar opções como Não Perturbe, perfil de energia e wallpaper. Começar por alternância manual; automações ficam para depois.
5. **Tela de configurações da shell:** controles da barra, ranking por uso no launcher e pasta de wallpapers estão implementados. Próximos candidatos: preferências adicionais do launcher e opções que ainda estejam fixas; defaults seguros para instalação nova. A revisão de telas menores fica para depois, conforme preferência do usuário.
6. **Gravação de tela:** escolher ferramenta e formatos antes de fechar dependências.
7. **DNS manual IPv4/IPv6 no menu de rede:** permitir retornar ao DNS automático, exibir estado atual e validar dados; avaliar integração NetworkManager e custo de dependência.

## Recomendações inspiradas no end-4

A referência é a cópia local em `~/Downloads/end-4-dotfiles`, especialmente `dots/.config/quickshell/ii/modules/waffle`. Essas ideias são recomendações para avaliar; não significam autorização automática para implementar cada feature.

### Prioridade recomendada

1. **Prévia de janelas sob demanda:** implementada nos números dos workspaces: após 450 ms de hover, mostra ao vivo a janela representativa daquele workspace e fecha ao sair do número. Workspaces vazios não iniciam captura; a captura ao vivo existe somente enquanto a prévia está carregada. Se o compositor não fornecer o protocolo de exportação de toplevel do Hyprland, mostra uma mensagem de indisponibilidade. Referências locais: `modules/Workspaces.qml` e `modules/WindowPreview.qml`; no end-4: `modules/waffle/bar/tasks/TaskAppButton.qml` e `TaskPreview.qml`.
2. **Unificar componentes visuais duplicados:** rodada ampla concluída para controles recorrentes: `IconButton` cobre controles de ícone em menus, `LabelButton` cobre ações curtas de texto, `ThemedTextField` cobre campos de busca/entrada, `ThemedSlider` padroniza sliders de áudio e `ThemeScrollBar` agora é usado pelas listas roláveis. Controles compostos e visualmente específicos permanecem locais. Referências: `modules/waffle/looks/WButton.qml`, `WTextField.qml`, `WScrollBar.qml`.
3. **Coordenar animação de saída com lazy loading:** implementado nos overlays Launcher, Clipboard, Wallpaper e Wallhaven. `PopupLoadState` mantém cada janela e seu `LazyLoader` ativos por 40 ms além da animação de 400 ms; o conteúdo perde foco/interação assim que o fechamento começa. Outros pop-ups sem animação de saída não precisam de retenção adicional.

### Ideias condicionais

- **Toggles configuráveis e paginados:** o end-4 permite escolher e ordenar toggles e os distribui em páginas. Vale considerar se a lista fixa crescer ou se houver pedido de personalização; acrescenta UI e estado persistente, então não é necessário para o painel atual. Referência: `actionCenter/mainPage/MainPageBodyToggles.qml`.
- **Busca por categorias e painel de detalhes no launcher:** o end-4 apresenta resultados por categoria, limita resultados e mostra uma prévia. A busca atual do shell já tem ranking aproximado e por uso, adequado para uma lista somente de apps. Categorias para ações/arquivos só fazem sentido junto com a busca ampliada.
- **Ações contextuais e prévias de tarefas:** abrir, alternar, fechar e fixar apps pode crescer a partir do módulo da aplicação focada, se houver interesse em uma taskbar mais completa.

### O que não copiar sem motivo

- Não substituir Material 3/Matugen por Acrylic/Fluent; são identidades visuais diferentes.
- Não separar o painel unificado em laterais independentes só por parecer com o end-4; o painel único foi uma escolha deliberada.
- Não adicionar pages, preferências ou serviços em segundo plano sem uma necessidade percebida.
- Capturas e prévias de janela têm custo; usar temporizadores, limitar quantidade e ativar somente sob interação.

## Avaliação do Hyprperk

Referência consultada: cópia local `~/Downloads/hyprperks-dotfiles-main/v0.56.0/dotfiles`. Esta avaliação é uma leitura estática; não implica copiar a configuração ou suas dependências.

### Padrões que valem considerar

- **Separar estado e operações da interface:** serviços menores para Wi-Fi, Bluetooth e ações de sessão podem reduzir a responsabilidade de `modules/ArchMenu.qml`. O menu deve continuar sendo dono da apresentação; os serviços cuidam de comandos, estados, erros e concorrência.
- **Evitar comandos duplicados:** antes de iniciar um processo de rede/dispositivo, verificar se já existe operação equivalente em andamento. Expor estados como `scanning`, `connecting` e `toggling` também permite feedback claro na UI.
- **Criar processos de comando sob demanda e destruí-los ao terminar:** o padrão de callback do Hyprperk pode ser útil para operações com vários comandos ou que precisem recolher stdout/stderr. Aplicar só onde simplifica o fluxo; processos fixos existentes não precisam ser reescritos sem benefício demonstrado.
- **Manter coleções estáveis quando a UI depende delas:** atualizar/adicionar/remover itens em listas tipadas pode evitar reconstruções desnecessárias e facilitar seleção/foco em listas de redes e dispositivos.
- **Configuração editável em JSON:** `FileView` + `JsonAdapter` é uma opção para preferências que realmente devam ser ajustáveis pelo usuário, como módulos da barra ou comportamento de painéis. Só introduzir junto com uma necessidade concreta e defaults seguros.
- **Unificar o ciclo de vida dos pop-ups:** o padrão `PopupHandle` + `LazyLoader` pode orientar a centralização de abertura, fechamento, foco e animação. O shell já usa carregamento sob demanda; avaliar isso ao corrigir diferenças repetidas entre menus, sem migrar todos de uma vez.
- **Reutilizar widgets recorrentes:** continuar consolidando botões, sliders, cartões e scrollbars em componentes compartilhados quando houver repetição real. O projeto já possui essa base.

### Padrões que não valem copiar como padrão geral

- **Timer de 1 s para forçar o redesenho dos cantos:** o código do Hyprperk identifica isso como workaround de renderização. Só usar se o defeito aparecer reproduzivelmente no arredondamento deste shell.
- **Polling permanente de métricas:** o `SystemState.qml` mantém processos de CPU, memória, temperatura e rede ativos e os repete a cada 5 s. Isso não combina com a preferência do projeto por consultas sob demanda/eventos; manter métricas detalhadas limitadas ao painel aberto ou a um intervalo justificado.
- **Vários `nohup`/processos em background no fluxo de wallpaper:** podem criar concorrência entre geração Matugen e hooks de GTK/KDE/Quickshell. Preservar uma sequência observável e registrar falhas é preferível neste projeto.
- **Replicar a estrutura de configuração inteira do Hyprperk:** é ampla e adicionaria manutenção sem uma necessidade equivalente; trazer apenas os pontos de configuração que forem solicitados.
- **Copiar a identidade visual Fluent/Acrylic:** manter Material 3/Matugen como identidade do shell.

### KDE e Matugen

- A cópia do Hyprperk consultada usa `qt6ct` com um arquivo de cores gerado pelo Matugen e configura `Papirus-Dark` como tema de ícones; isso não demonstra recoloração dinâmica dos ícones Papirus pelo Matugen.
- O pacote local `kde-material-you-colors` fixa o destino em `~/.config/kdeglobals` (`settings.py`, `KDE_GLOBALS = HOME + "/.config/kdeglobals"`). Não foi encontrada opção de saída no wrapper atual. A organização em `~/.config/kde/kdeglobals` permanece uma decisão em aberto; um link em `~/.config/kdeglobals` é a compatibilidade sugerida, mas ainda não foi aplicado.

## Refinamento visual já concluído

- `Theme.qml` tem escala semântica de superfícies, bordas, espaçamento, raios, movimento e estados interativos.
- Há componentes compartilhados para cartões, botões de ícone e texto, abas segmentadas, campos de texto, sliders, scrollbars, foco/dismiss e animação.
- `widgets/ActionButton.qml` é compartilhado entre Wallpaper e Wallhaven para manter estilo e foco consistentes.
- Notificações animam expansão e entrada/remoção de grupos.
- O grupo da direita da barra ganha fundo colorido no hover, foco e painel aberto, sem borda luminosa.
- O calendário é ancorado no rodapé e seu recolhimento afeta a área própria; a lista ocupa a região rolável.
- Painel ajusta largura em telas estreitas; listas Wi-Fi/Bluetooth têm altura limitada, rolagem interna e foco trazido à vista.
- Menus Wallpaper, Clipboard e Wallhaven usam o Application Launcher como referência visual, mantendo área extra nas grades de imagem.
- Contraste e layout em múltiplas resoluções/monitores ainda precisam de inspeção manual.

Diretrizes visuais:

- Preferir cores semânticas Material 3 em vez de compor todos os níveis por transparência sobre texto.
- Reservar destaque para seleção, foco e ações principais.
- Manter animações curtas e funcionais; não animar valores que reposicionem controles sem necessidade.
- Usar tokens compartilhados para padrões repetidos, sem transformar cada espaçamento isolado em token.

## Auditoria técnica e eficiência

Leituras estáticas anteriores não foram medições de CPU/RAM. Os itens abaixo são hipóteses de manutenção, não problemas confirmados:

### Revisão atual — 2026-10-16

- **Bateria pode deslocar o ícone ao carregar:** `modules/Battery.qml` mostra o raio somente durante o carregamento e o `Row` é centralizado pela largura dinâmica. Reservar sempre o espaço do raio (ou removê-lo) para evitar que percentual e anel mudem de posição entre os estados.
- **Barra em telas estreitas:** `modules/Bar.qml` reduz alguns elementos por faixas de largura, mas mantém grupos ancorados em posições fixas. Validar especialmente telas abaixo dos limites de 1000 px e conferir colisões entre workspaces, status, relógio e bandeja; ajustar o layout se houver sobreposição.
- **Código sem uso aparente:** `Battery.qml` atualiza `hovered`, mas nenhum comportamento consulta esse estado; `Theme.qml` declara `batteryTextSize`, sem uso aparente após a mudança visual. Confirmar com busca global e remover ou reutilizar esses itens na próxima limpeza.

Esses pontos foram identificados por leitura estática; não foram reproduzidos em execução nesta revisão.

1. **Múltiplos monitores/resolução baixa:** validar colisões entre grupos da barra, bandeja e pop-ups na menor tela; depois ajustar limites e posicionamento com evidência.
2. **Separação do Arch Menu:** `modules/ArchMenu.qml` é extenso e reúne UI, estado e operações. Extrair responsabilidades melhora manutenção; não se espera ganho de runtime só pela divisão.
3. **Tokens e componentes comuns:** centralizar apenas padrões recorrentes quando os arquivos forem editados.
4. **Wallhaven:** o cache de páginas existe enquanto o seletor está aberto e é limpo ao fechar ou iniciar outra busca; limitar mais só se sessões longas mostrarem consumo relevante.
5. **API nativa de rede/Bluetooth:** avaliar somente se reduzir parsing/polling sem perder cobertura funcional.
6. **OSDs:** extrair layout comum se houver mudanças futuras; ganho é de manutenção, não de performance.
7. **Power profiles:** polling anterior de 30 s era baixo; API nativa pode ser avaliada se representar bem estado indisponível.
8. **Launcher:** inventário anterior encontrou cerca de 92 arquivos `.desktop`; busca em lista e `ListView` não justificam reescrita em C++ sem medição.
9. **Métricas de CPU/memória:** consultas a `/proc/stat` e `/proc/meminfo` a cada 5 s não eram prioridade na auditoria estática.
10. **Brilho:** registros de auditoria antigos mencionavam polling sysfs a cada 200 ms. Estado posterior priorizou IPC/detecção sob uso; não reintroduzir polling sem medir e revisar o comportamento atual.
11. **Wlogout:** `widgets/WLogout.qml` é o único componente; o modo standalone e os arquivos de compatibilidade (`Wlogout.qml`, `WlogoutShell.qml`, `WlogoutOverlay.qml`, `WlogoutButtons.qml`) foram removidos em 2026-11-06. As cores vêm de `Theme.qml`.
12. **Scripts/cores:** scripts do shell estão dentro do projeto; Matugen, wrappers Qt/KDE e outras ferramentas de sistema continuam dependências externas. Não confundir script do projeto com dependência do sistema.

## Dependências do sistema

Dependências são necessárias para as features correspondentes, não necessariamente para carregar todas as partes da shell.

### Base e sessão

| Dependência | Usada por | Estado |
| --- | --- | --- |
| Quickshell com módulos QML usados: Hyprland, Wayland, Networking, Bluetooth, PipeWire, MPRIS e UPower | Shell inteira | Build precisa incluir módulos importados. |
| Hyprland e `hyprctl` | Workspaces, monitores, IPC e Wallhaven | Necessários nesta configuração. |
| D-Bus de sessão | Notificações, tray e integrações | Necessário. |
| JetBrainsMono Nerd Font e Material Symbols Rounded | Texto e ícones | Necessárias para a aparência e ligaduras esperadas. |
| Aplicativos com arquivos `.desktop` | Launcher | Cada aplicativo precisa de entrada para aparecer corretamente. |

### Serviços e ferramentas

| Dependência | Usada por | Estado |
| --- | --- | --- |
| NetworkManager ativo | Wi-Fi via Quickshell Networking | Necessário para Wi-Fi. |
| BlueZ (`bluetoothd`) e `bluetoothctl` | Estado, descoberta, pareamento e operações Bluetooth | Necessários para Bluetooth. |
| PipeWire e gerenciador de sessão (normalmente WirePlumber) | Controles de áudio e indicadores de captura | Necessários para áudio/microfone. |
| Player MPRIS compatível | Módulo Media | Opcional. |
| UPower e `upower` | Bateria e propriedades | Necessários para bateria; métricas variam por hardware. |
| `busctl` | Saúde/ciclos no Battery Menu | Necessário para consultas extras. |
| `power-profiles-daemon` e `powerprofilesctl` | Perfis de energia | Opcionais; menu verifica disponibilidade. |
| `brightnessctl` | Alterar brilho | Necessário em hardware compatível; conferir permissões. |
| `curl` | Busca/download Wallhaven | Necessário para Wallhaven. |
| `grim` e ImageMagick (`magick`) | Screenshot e recorte em pixels | Necessários para o seletor integrado. |
| `wl-clipboard` (`wl-copy`) | Copiar screenshot | Necessário para enviar captura à área de transferência. |
| `libnotify` (`notify-send`) | Confirmação após screenshot/teste de notificações | Opcional para screenshot; útil para validação. |
| `swww` ou `awww` | Aplicar wallpapers | Um deles e seu daemon de sessão são necessários. |
| Matugen | Geração de paleta | Necessário para atualizar cores pelo wallpaper. |
| `kde-material-you-colors` e wrapper Matugen correspondente | Sincronização de cores KDE/Qt | Dependência opcional do ambiente integrado; `scripts/apply_colors.sh` verifica wrapper. |
| `kitty`, hooks GTK, `pywalfox`, `spotifast`, Neovim | Pós-hooks do `scripts/apply_colors.sh` | Opcionais; script tenta executar apenas quando disponíveis. Mako não é mais usado (hook removido). |
| `hyprlock` | Bloqueio de sessão | Necessário para Lock. |
| `hyprshutdown` | Wlogout e comandos de sessão | Necessário para o fluxo Wlogout atual. |
| `systemctl`, `shutdown`, `reboot` | Ações de energia | Necessários para as ações correspondentes; ambiente atual usa systemd. |
| `find`, `mkdir`, `ln`, `sh`, `bash`, `awk`, `cat`, `which`, `grep`, `cp`, `pkill` | Scripts e helpers | Ferramentas padrão esperadas no ambiente. |
| `wl-paste` e Python 3 | Captura do clipboard | Necessários para `services/ClipboardHistory.qml` e `scripts/clipboard-capture.py`; não requer `cliphist`. |

### Checklist de instalação nova

1. Instalar Quickshell com os módulos usados e iniciar D-Bus/Hyprland corretamente.
2. Instalar/iniciar NetworkManager, BlueZ, PipeWire + gerenciador de sessão e UPower conforme as features desejadas.
3. Instalar JetBrainsMono Nerd Font e Material Symbols Rounded.
4. Escolher `swww` ou `awww`, iniciar daemon e instalar Matugen.
5. Instalar dependências opcionais de integração de cores (wrapper KDE/Qt, Kitty, hooks GTK) somente se desejadas.
6. Instalar opcionais de hardware/sessão usados: `brightnessctl`, `power-profiles-daemon`, `hyprlock`, `hyprshutdown`.
7. Garantir que só um servidor de notificações esteja ativo; atualmente é Quickshell. Mako pode ser usado para teste apenas se o servidor da shell estiver desligado.
8. Manter um manifesto de instalação por distribuição separando obrigatório, opcional e planejado.

## Histórico de validação e cuidados

- Em 2026-10-24, começou a configuração persistente em `settings.json`, na raiz do shell. O arquivo é criado com defaults se ausente e contém `bar.showFocusedApp` e `bar.showDate`; alterações externas são observadas. O botão de ação duplicado em Wallpaper/Wallhaven foi extraído para `widgets/ActionButton.qml`.
- Em 2026-10-24, o ArchMenu ganhou uma aba Configurações com switches para `bar.showFocusedApp` e `bar.showDate`; os valores continuam sendo gravados automaticamente em `settings.json` pelo `Preferences.qml`.
- Em 2026-10-24, as configurações persistentes da barra foram ampliadas com `showTray`, `showDeviceIndicators`, `showSystemStatus` e `showMedia`. Todos usam `true` como padrão para manter a barra atual; a aba Configurações ganhou switches correspondentes.
- Em 2026-10-24, `launcher.prioritizeUsage` passou a controlar o desempate dos resultados do launcher por uso recente. O padrão `true` preserva o ranking atual; desativado, resultados de relevância igual seguem ordem alfabética.
- Em 2026-10-24, a pasta carregada com sucesso no seletor de wallpapers passou a ser persistida em `wallpaper.directory` e compartilhada com os downloads do Wallhaven; uma pasta inválida não substitui a última pasta válida.
- Em 2026-10-25, a duração padrão dos pop-ups passou a ser ajustável de 1 a 10 segundos em `notifications.defaultTimeoutSeconds`, com padrão de 3 segundos. O timeout positivo enviado pelo aplicativo continua valendo; `0` permanece sem expiração.
- Em 2026-10-25, o runtime local entregou timeouts positivos em milissegundos, apesar da documentação da propriedade indicar segundos. Multiplicar por 1000 fazia `notify-send -t 3000` durar 50 min; o timer agora usa o valor recebido diretamente. O teste confirmou o disparo em 3000 ms e os logs temporários foram removidos.
- Em 2026-10-25, tentei mudar o foco do overlay de `OnDemand` para `Exclusive` para liberar o mouse em jogos; o usuário confirmou que não resolveu. Essa tentativa foi substituída pelo fluxo `hyprshot --freeze` descrito abaixo.
- Em 2026-10-25, após o foco exclusivo não resolver, comparei com Hyprperk e end-4: ambos usam congelamento externo (`grimblast --freeze` ou `hyprshot --freeze`, com `hyprpicker`) antes do seletor. O Quickshell agora delega região/janela ao `hyprshot --freeze`; `hyprshot`, `hyprpicker` e `slurp` estão instalados.
- Em 2026-10-26, o usuário validou que o seletor `hyprshot --freeze` funciona corretamente em jogos fullscreen; removida a pendência de teste manual nesse cenário.
- Em 2026-10-26, a barra ganhou um botão permanente de microfone ao lado do volume para alternar o mute do dispositivo de entrada padrão. Os seletores de dispositivo do Mixer agora preferem o default ativo e usam o dispositivo preferido como fallback apenas quando o default não aparece na lista.
- Em 2026-10-26, o usuário confirmou que o botão de microfone e a seleção/fallback de dispositivos funcionam corretamente.
- Em 2026-10-24, grupos ocultos da barra passaram a reservar largura zero. As margens entre mídia/status agora acompanham a visibilidade, para recompor o espaço ao ocultar módulos nas configurações.
- Em 2026-10-24, o botão DND foi removido da aba Atalhos por duplicar o controle dos controles rápidos; `SUPER+N` e o indicador da barra permanecem.
- Em 2026-10-24, Avisos, Mixer, Bateria e Configurações passaram a compartilhar uma única área `StackLayout` no ArchMenu. Isso mantém a região superior independente do conteúdo ativo da aba e evita que páginas inativas participem da geometria.
- Em 2026-10-24, o perfil de energia podia ficar no default `balanced` quando a aba Bateria consultava antes de terminar a detecção do `powerprofilesctl`. O serviço agora busca o perfil assim que confirma o executável e só aceita valores conhecidos; `powerprofilesctl get` retornou `performance` nesta sessão.
- Em 2026-10-24, a largura do ArchMenu passou a respeitar a área disponível do monitor; abaixo de 360 px, a navegação usa ícones com tooltips em vez de rótulos, e os nomes dos cartões de Wi-Fi/Bluetooth podem ser reduzidos e truncados sem invadir os controles.
- Em 2026-10-24, telas abaixo de 800 px de altura usam cartões de conectividade, microfone e mídia mais baixos, com capa e espaçamento reduzidos. A área central do ArchMenu permanece rolável acima do calendário compacto.
- Em 2026-10-24, BatteryDetails passa a usar uma coluna para as métricas em painéis abaixo de 340 px e recolhe os rótulos dos perfis de energia para ícones com tooltip; isso preserva leitura e área de toque em largura curta.
- Em 2026-10-24, foi criado `modules/PopupGeometry.js` para limitar larguras/alturas ao monitor; Calendário, Mídia, Uso do Sistema, ArchMenu e notificações passam a receber a tela de origem explicitamente. Uso do Sistema e pilhas de notificações ganham rolagem vertical em telas baixas, e cartões de launcher, clipboard, cheatsheet e seletores evitam dimensões negativas em janelas pequenas.
- Em 2026-10-24, os botões locais de fechar do ArchMenu/menu de áudio e os controles de energia/expansão de Wi-Fi e Bluetooth no ArchMenu passaram a usar `widgets/IconButton.qml`, reduzindo duplicação de estilo e mantendo rótulos acessíveis e ações existentes.
- Em 2026-10-24, a prévia de janela passou do título do aplicativo para cada número de workspace: após 450 ms de hover, mostra ao vivo a janela representativa daquele workspace e descarrega o componente ao sair do número. O stream existe apenas enquanto a prévia está carregada; workspaces vazios não capturam. O recurso depende de `hyprland-toplevel-export-v1`.
- Em 2026-10-24, os controles repetidos foram consolidados: botões de ícone usam `widgets/IconButton.qml`, ações de texto usam `widgets/LabelButton.qml`, campos de busca/entrada usam `widgets/ThemedTextField.qml`, sliders de áudio usam `widgets/ThemedSlider.qml` e as barras de rolagem passaram a usar `widgets/ThemeScrollBar.qml`. Ações compostas e controles com layout próprio (como cabeçalhos de grupos) continuam locais.
- Em 2026-10-24, os overlays Launcher, Clipboard, Wallpaper e Wallhaven passaram a manter o `PanelWindow` e o `LazyLoader` ativos durante a animação de saída. `widgets/PopupLoadState.qml` segura o carregamento por 440 ms, cobrindo os 400 ms das transições de opacidade/escala e uma pequena margem; foco e interação são desativados assim que o fechamento começa. O `qs` recarregou com `Configuration Loaded`.
- Em 2026-10-24, a inicialização do Quickshell detectou e corrigiu dois erros da revisão responsiva: faltava importar `QtQuick.Controls` para o `ScrollView` do Uso do Sistema, e faltava fechar o bloco externo em `NotificationPopups.qml`. Depois disso, a configuração carregou e o ArchMenu abriu sem erros QML.
- Em 2026-10-24, o botão de detalhes do Bluetooth agora fecha a lista mesmo quando o adaptador está desligado; abrir/fechar os detalhes deixou de depender do estado de energia do adaptador.

- Em 2026-10-16, o mixer por aplicativo foi alinhado ao modelo do end-4: nós PipeWire são expostos pelo serviço de áudio em listas `list<var>`, o `Repeater` usa `ScriptModel` e mute/volume passam por funções com checagem do nó. `wpctl status` confirmou duas streams de saída ativas do Firefox; a interação visual e os ajustes ainda precisam de validação manual.
- Em 2026-10-16, ao revisar o seletor de screenshots, o log mostrou que o campo `client.monitor` é numérico; comparar com o nome da saída deixava a seleção de janelas vazia. O filtro agora usa `monitor.id`. O `Image` do fundo também passou a receber o caminho só após a captura temporária terminar, evitando tentativa de leitura antes do arquivo existir. `grim` foi validado com a saída `DP-1` em 1920×1080, e o cancelamento remove o arquivo temporário. A cópia final de uma janela/região ainda requer validação manual.
- Em 2026-10-16, a lista Bluetooth passou a reagrupar após atualizar conexões e ordenar conectados/pareados/disponíveis. A descoberta começa ao expandir os detalhes e termina ao recolher ou fechar o painel; removido um refresh de dispositivos desnecessário ao parar a busca.
- Em 2026-10-16, consulta ao BlueZ confirmou `hci0` com `Soft blocked: yes`, `Hard blocked: no` e estado `off-blocked`. O botão agora tenta retirar o bloqueio leve usando `rfkill`; se a política do sistema negar a ação, o controle pode continuar bloqueado.
- Em 2026-10-07, o Quickshell assumiu `org.freedesktop.Notifications`; `notify-send` retornou sucesso e o usuário confirmou o pop-up. A linha de inicialização do Mako foi comentada no autostart.
- Para notificações sem timeout definido (`-1`), o tempo padrão é configurável entre 1 e 10 s, com 3 s por padrão. Valores positivos recebidos são respeitados em milissegundos; `0` mantém o aviso até fechamento manual. Até 5 pop-ups aparecem simultaneamente. Não Perturbe suprime pop-ups, mantendo notificações no centro. Imagens aparecem no pop-up, sem retenção no histórico. Ações são suportadas enquanto a notificação permanece ativa; resposta inline não é anunciada como suportada.
- O X do pop-up arquiva como lida no centro; X dentro do centro remove do histórico. Histórico de notificações limitado a 50 entradas e mantido em memória.
- Não iniciar Mako junto com o servidor do Quickshell, pois ambos disputam `org.freedesktop.Notifications`. Para rollback, desligar o servidor da shell antes de reativar Mako.
- Referências históricas da API: [NotificationServer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/) e [Notification](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/Notification/).

## Apêndice: documentos de origem consolidados

As três seções abaixo preservam os documentos anteriores para não perder decisões, auditorias, estimativas e detalhes. Elas são registros históricos: quando divergirem do **Estado atual** ou das correções acima, prevalecem as seções atuais deste diário.



# Origem: FEATURES.md (snapshot anterior)

# Ideias de recursos para o Quickshell

Este documento registra funcionalidades planejadas e o estado das que já tiveram uma primeira versão implementada. Ao planejar cada uma, priorizar carregamento sob demanda e evitar serviços ou consultas em segundo plano sem necessidade.

## Sugestões

1. **Painel de áudio** — primeira versão implementada
   - Ajustar a saída padrão, silenciar o microfone e indicar aplicativos conectados à captura.
   - Abrir o `pavucontrol` para seleção de dispositivos e ajustes avançados.
   - Monitorar conexões de captura do PipeWire por eventos, sem polling.

2. **Central de atalhos configuráveis**
   - Reunir ações como bloquear a tela, alternar Não Perturbe e abrir ferramentas do sistema.
   - Oferecer botões no shell e atalhos de teclado configuráveis.

3. **Painel unificado de controles e notificações** — primeira versão implementada
   - Reunir controles rápidos de Wi-Fi, Bluetooth e Não Perturbe, sliders de brilho e volume, mídia ativa e notificações num painel vertical.
   - Manter os detalhes de redes e dispositivos Bluetooth recolhidos até serem abertos; o perfil de energia continua no menu da bateria.
   - Mostrar o tempo ligado no cabeçalho e abrir o wlogout por um único botão de energia.
   - O painel é carregado sob demanda e o conteúdo rola em telas menores.

4. **Indicadores de microfone e câmera** — primeira versão implementada
   - Mostrar na barra quando um aplicativo está capturando áudio ou usando uma câmera pelo PipeWire, identificando os aplicativos conectados.
   - O ícone do microfone permite silenciar/reativar a captura com clique ou teclado; o estado e os aplicativos também aparecem no menu de áudio.
   - A câmera tem indicador e tooltip com os aplicativos em uso. A detecção acompanha conexões ativas do PipeWire, sem polling.
   - Limitação da primeira versão: acessos diretos a dispositivos V4L2 que não passem pelo PipeWire podem não aparecer. Não há controle genérico de mute da câmera implementado.

5. **Busca ampliada no launcher**
   - Integrar busca de arquivos, ações e comandos ao launcher atual.
   - Manter a interface sob demanda e avaliar dependências e custo de indexação antes de escolher a estratégia de busca.

6. **Resumo de bateria e energia na barra**
   - Exibir previsões e informações de saúde usando os dados já disponíveis no menu da bateria.
   - Evitar consultas adicionais contínuas.

7. **Perfis de contexto**
   - Agrupar configurações como Não Perturbe, perfil de energia e wallpaper em uma ação.
   - Começar com alternância manual; automações podem ser consideradas depois.

8. **Histórico da área de transferência** — primeira versão implementada
   - Pesquisar e reutilizar itens recentes pelo menu do QuickShell.
   - O histórico existe apenas na sessão, guarda texto com limites de quantidade e tamanho e pode ser limpo manualmente.
   - Ainda não há detecção de senhas; evitar copiar conteúdo sensível ou limpar o histórico após usá-lo.

## Ordem inicial sugerida

O histórico da área de transferência, o painel de áudio, a primeira versão dos indicadores de microfone e câmera e a primeira versão do **painel unificado de controles e notificações** estão implementados. Os próximos focos são a **central de atalhos** e a **busca ampliada do launcher**, mantendo interfaces sob demanda e evitando consultas contínuas em segundo plano.


# Origem: VISUAL_REFINEMENT_PLAN.md (snapshot anterior)

# Plano de refinamento visual

Objetivo: aproximar a consistência e a hierarquia do end-4 sem abandonar o Material 3 dinâmico do Matugen nem a identidade atual do shell.

## Base implementada

- Adicionada uma escala semântica compartilhada em `Theme.qml` para superfícies, bordas, espaçamento, raios e estados interativos.
- Adicionada uma escala compartilhada de movimento inspirada no end-4, com curvas Bézier expressivas e tempos distintos para efeitos, deslocamento, entrada, saída e redimensionamento.
- Criados componentes compartilhados de cartão, botão de ícone e aba segmentada; aplicados ao painel, calendário, histórico e abas do mixer.
- A lista de notificações agora anima a expansão dos grupos e a entrada/remoção de grupos.
- O grupo direito da barra ganha fundo colorido e transição ao passar o mouse, ao receber foco do teclado ou enquanto o painel correspondente estiver aberto.
- O calendário continua numa região ancorada no rodapé do painel; seu recolhimento afeta sua própria área, enquanto a lista ocupa a área rolável disponível.
- Em telas estreitas o painel limita sua largura ao espaço disponível; o estado recolhido/expandido do calendário é compartilhado entre aberturas durante a sessão.

## Refinamentos concluídos

- O painel mantém controles principais e conteúdo numa área rolável, enquanto calendário fica ancorado no rodapé.
- As listas expandidas de Wi-Fi e Bluetooth têm altura limitada de acordo com a tela, rolagem própria e barra de rolagem discreta.
- Ao navegar com Tab, o item focado nas listas é trazido à vista tanto na lista interna quanto no painel.
- As linhas de rede e dispositivos expõem nome e estado ao leitor de tela; ações principais e de remoção podem ser acionadas pelo teclado.
- As barras de rolagem do painel e do histórico usam a mesma aparência temática.
- Estados de foco usam cores semânticas de primeiro plano e destaque; o grupo da barra mantém fundo colorido no hover/foco, sem borda luminosa.
- O calendário reduz espaçamentos em telas baixas e mantém seu estado aberto/recolhido entre aberturas do painel.
- Workspaces, calendário, histórico de notificações, sliders do OSD, botões de ícone, abas e grupos da barra usam transições alinhadas à escala de movimento compartilhada.
- Menus de áudio, bateria, controles/notificações, mídia, calendário e uso do sistema entram com deslocamento curto e curva de desaceleração expressiva.

## Verificação visual pendente

- Conferir contraste em diferentes paletas Matugen e recorte/rolagem em resoluções baixas e em mais de um monitor.
- A recarga automática do Quickshell foi observada, mas a verificação manual em telas e monitores distintos depende de abrir o painel nessas condições.

## Diretrizes

- Usar cores de superfície do Material 3 em vez de construir todos os níveis com transparências sobre o texto.
- Reservar a cor de destaque para seleção, foco e ações primárias.
- Manter animações curtas e funcionais; não animar valores que causem reposicionamento inesperado de controles.
- Manter menus sob demanda e não adicionar polling visual em segundo plano.


# Origem: system_plan.md (snapshot anterior)

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
- Seletor de screenshot integrado via `hyprshot --freeze`, com seleção de região/janela, gravação em Screenshots e cópia para o clipboard.

## Roadmap

### Prioridade 1 — concluir a validação das notificações

O serviço, os popups, o centro, o indicador e o IPC já estão implementados. Em 2026-10-07, o Quickshell assumiu `org.freedesktop.Notifications`; `notify-send` retornou sucesso e o usuário confirmou que viu o popup. A linha de inicialização do Mako está comentada no autostart.

Estado e comportamento atuais:

- Histórico limitado a 50 entradas e mantido em memória, sem gravar o texto das mensagens em disco.
- X do popup arquiva a notificação como lida no centro; X dentro do centro remove o item do histórico.
- Duração padrão ajustável entre 1 e 10 s para notificações sem timeout definido (`-1`); valores positivos informados pelo aplicativo são respeitados em milissegundos e zero mantém a notificação até ela ser fechada.
- Até cinco popups aparecem ao mesmo tempo.
- Ações do aplicativo são suportadas enquanto a notificação permanece ativa. Resposta inline não é anunciada como suportada.
- Imagens aparecem nos popups e não ficam retidas no histórico.
- Não Perturbe suprime popups, mas preserva as notificações no centro.
- IPC: `shell toggleNotificationCenter`.

Validação manual que ainda vale fazer: imagens, botões de ação, urgências, timeouts solicitados pelos aplicativos, Não Perturbe, arquivar/remover, limpeza do histórico, reload e uso em múltiplos monitores. Não iniciar Mako junto com o servidor do Quickshell, pois ambos disputam o nome D-Bus. Rollback: desativar o servidor de notificações do Quickshell antes de reativar Mako.

Referências da API: [NotificationServer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/) e [Notification](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/Notification/).

### Prioridade 2 — evoluir o Arch Menu

- Seleção de dispositivos de saída/entrada, volume de saída e mute do microfone já estão implementados no Mixer; o usuário confirmou o botão da barra e o fallback dos dispositivos. Falta validar visual e funcionalmente os controles por aplicativo.
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

### Prioridade 5 — gravação de tela

A captura de tela por região e por janela já funciona via `hyprshot --freeze`, incluindo em jogos fullscreen. A gravação de vídeo continua planejada; escolher ferramenta e formatos antes de fechar dependências.

## Auditoria técnica e visual

Leitura estática de `Theme.qml`, `Colors.qml`, `shell.qml`, módulos e widgets em **2026-10-06**, considerando Quickshell 0.3.1. Não foram feitas medições de CPU/RAM nem validação completa de runtime. Os ganhos citados são estimativas, não medições.

### Ações de manutenção que valem considerar

1. **Validar resoluções e múltiplos monitores.** A barra posiciona grupos esquerdo, central e direito de forma independente; mídia pode ocupar até 350 px. Há risco de colisões em telas estreitas ou bandejas grandes, mas a leitura estática não confirma colisão em resolução específica. Alguns popups têm tamanho fixo e abrem abaixo da barra; Arch Menu tem lista Wi-Fi limitada/rolável, mas a lista Bluetooth e o painel total podem precisar de limites. Validar na tela menor e só então compactar, limitar altura/rolagem ou reposicionar para cima.
2. **Reduzir polling do brilho.** `services/Brightness.qml` consulta sysfs por processo a cada 200 ms. Considerar 500 ms–1 s e conferir a resposta às teclas Fn; benefício esperado é modesto, com possível pequeno atraso visual.
3. **Separar `ArchMenu.qml`.** O arquivo é muito grande e combina UI, estado e operações. Extrair por responsabilidade deve melhorar manutenção; não se espera ganho de runtime só pela divisão.
4. **Revisar idioma.** Concluído em 2026-11-06: toda a UI está em inglês. Localização configurável só se houver intenção de suportar idiomas diferentes.
5. **Documentar famílias de ícones.** A configuração usa JetBrainsMono Nerd Font e Material Symbols Rounded. Ambas são dependências visuais atuais; centralizar tamanhos recorrentes no tema e declarar `font.family` onde hoje depende da fonte padrão.
6. **Centralizar tokens visuais recorrentes.** Raios, bordas, scrim e fundos de legenda aparecem como literais em launcher, seletores, Arch Menu e popups. Adicionar tokens semânticos para superfícies/campos quando esses arquivos forem editados; não transformar todo espaçamento isolado em token.
7. **Rever carregamento de cores do Wlogout.** Resolvido em 2026-11-06: o modo standalone foi removido e o componente usa apenas `Theme.qml`.
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
| `hyprshot`, `hyprpicker` e `slurp` | Captura congelada e seleção de região/janela | Necessários para o seletor atual; `hyprpicker` congela a saída quando `hyprshot --freeze` é usado. |
| `grim` | Captura de imagem usada por `hyprshot` | Dependência do hyprshot. |
| `wl-clipboard` (`wl-copy`) | Copiar screenshot | Obrigatório para enviar a captura à área de transferência. |
| `libnotify` (`notify-send`) | Confirmação após screenshot | Opcional; a captura e cópia continuam funcionando sem ele. |
| `swww` ou `awww` | Aplicar wallpapers | Um deles é necessário e seu daemon deve iniciar na sessão. O código tenta `swww` e depois `awww`. |
| Matugen e `scripts/apply_colors.sh` | Atualização de paleta após wallpaper | Necessários para o fluxo atual. O script fica dentro do projeto e concentra todos os hooks. |
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
| Gravação de tela | A escolher | Selecionar ferramenta e formatos antes de adicionar à instalação. |

## Checklist para instalação nova

1. Instalar uma build do Quickshell que inclua os módulos listados e iniciar a sessão D-Bus/Hyprland corretamente.
2. Instalar/iniciar NetworkManager, BlueZ, PipeWire + gerenciador de sessão e UPower conforme as features desejadas.
3. Instalar fontes JetBrainsMono Nerd Font e Material Symbols Rounded.
4. Escolher `swww` ou `awww`, iniciar seu daemon e instalar Matugen.
5. O `scripts/apply_colors.sh` já faz parte do projeto; confirmar apenas que o Matugen está instalado e que o `config.toml` tem os templates (sem `post_hook`).
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
