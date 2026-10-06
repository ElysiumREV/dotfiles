# Plano: notificações nativas no Quickshell

## Objetivo

Substituir o Mako pelo sistema de notificações do Quickshell, mantendo avisos temporários e adicionando um centro de notificações acessível pela barra e por atalho/IPC.

O projeto usa Quickshell 0.3.1, cuja API `Quickshell.Services.Notifications` implementa o protocolo Desktop Notifications para receber notificações de aplicativos.

## Arquitetura proposta

### Serviço de notificações

Criar `services/Notifications.qml` como serviço único, instanciado pelo `ShellRoot` em `shell.qml`. Ele será responsável por:

- possuir o `NotificationServer` e receber as notificações;
- manter os modelos de notificações ativas e recentes;
- controlar o contador de notificações não lidas;
- oferecer operações compartilhadas para dispensar uma notificação, limpar o histórico e alternar o modo Não Perturbe.

Notificações que precisem continuar acompanhadas devem ser marcadas como `tracked`. O `NotificationServer` oferece `trackedNotifications` como modelo das notificações acompanhadas. [Documentação do NotificationServer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/)

### Avisos temporários

Criar `widgets/NotificationPopups.qml` para exibir os avisos recebidos. A primeira versão seguirá a configuração visual atual do Mako:

- posição no canto superior direito;
- no máximo cinco avisos visíveis;
- tempo padrão de seis segundos, respeitando o tempo pedido pelo aplicativo quando aplicável;
- ícone, aplicativo, título, corpo e nível de urgência;
- botões para dispensar e acionar ações disponibilizadas pelo aplicativo.

A API de `Notification` expõe os campos de conteúdo, urgência, ações, tempo de expiração e métodos para dispensar ou expirar avisos. [Documentação de Notification](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/Notification/)

### Centro de notificações

Criar `modules/NotificationCenter.qml` com o visual do projeto e acesso pela barra e pelo IPC. O centro deve incluir:

- lista das notificações recentes;
- indicação de não lidas;
- ação para dispensar um item;
- ação para limpar o histórico;
- estado vazio claro;
- modo Não Perturbe, que silencia os avisos temporários sem deixar de registrar notificações no centro.

Na primeira versão, o histórico será limitado e mantido em memória durante a execução do Quickshell. Não será salvo o conteúdo das mensagens em disco. Os avisos recentes poderão aparecer no centro depois que o popup expirar; ações interativas serão oferecidas enquanto a notificação correspondente continuar ativa.

### Barra e IPC

- Adicionar à `modules/Bar.qml` um indicador de notificações, com contador ou ponto para itens não lidos.
- Adicionar uma chamada para abrir/fechar o centro no `IpcHandler` de `shell.qml`, seguindo o padrão já usado pelos outros recursos.
- Permitir que o centro seja aberto pelo clique no indicador ou por bind do Hyprland via IPC.

## Etapas de implementação

1. **Recepção:** criar o serviço e confirmar que notificações de aplicativos chegam ao Quickshell.
2. **Popups:** implementar layout, expiração, dispensar, urgência e ações.
3. **Centro:** implementar histórico recente, estado de leitura, contador, limpeza e modo Não Perturbe.
4. **Barra e IPC:** adicionar o indicador e o comando IPC para abrir/fechar o centro.
5. **Migração do Mako:** remover a inicialização do Mako do autostart quando o servidor do Quickshell estiver validado.
6. **Validação:** conferir texto, imagens, ações, expiração, reload do Quickshell, notificações durante Não Perturbe e posição em múltiplos monitores.

## Migração e rollback

O autostart atual em `~/.config/hypr/modules/autostart.lua` inicia `qs` e `mako`. Ambos disputam o serviço D-Bus `org.freedesktop.Notifications`, portanto só um deve atuar como daemon por vez.

Quando o servidor do Quickshell estiver pronto e validado:

1. remover `hl.exec_cmd("mako")` do autostart;
2. reiniciar a sessão ou parar o Mako e iniciar/recarregar o Quickshell;
3. confirmar que aplicativos enviam notificações ao Quickshell;
4. se houver problema, reativar Mako e parar o servidor de notificações do Quickshell.

## Critérios de conclusão

- Aplicativos comuns enviam notificações sem precisar de configuração individual.
- Os popups respeitam conteúdo, urgência, expiração e ações suportadas.
- O centro abre pelo clique na barra e por IPC/bind.
- Notificações recentes ficam acessíveis no centro após o popup sumir.
- Mako não é iniciado junto com o servidor de notificações do Quickshell.
- O rollback para Mako permanece simples caso a migração precise ser revertida.
