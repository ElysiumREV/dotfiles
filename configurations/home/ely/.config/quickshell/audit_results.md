# Auditoria atualizada — Quickshell

Revisão estática do diretório em **2026-10-06**, considerando Quickshell **0.3.1** e o código presente nesta configuração. O foco é decidir quais sugestões anteriores justificam o custo de implementação. Não foram feitas medições de CPU/RAM nem testes de execução; ganhos de desempenho abaixo são estimativas baseadas nos intervalos e caminhos de código observados.

## Resumo

Há uma otimização de processo com benefício plausível e baixo risco: reduzir o polling de brilho, hoje a cada 200 ms. O maior ganho de organização viria de dividir `modules/ArchMenu.qml`, que concentra interface, estado e operações de rede/Bluetooth. Uma apresentação compartilhada para os OSDs também reduziria manutenção, mas não deve mudar o desempenho perceptivelmente.

As sugestões antigas sobre a regra visual da bateria, realce do relógio, agrupamento visual da barra e limites de posição dos popups estão resolvidas ou ficaram desatualizadas. Não há evidência que justifique reescrever o application launcher em C++ ou otimizar sua RAM neste momento.

O Wallhaven agora consulta `hyprctl -j monitors` ao abrir, usa a maior resolução ativa como filtro mínimo da busca e tenta novamente sem filtro se a API não retornar resultados compatíveis. Isso filtra a busca, mas o download continua usando o arquivo original de `wallpaper.path`; ainda não há redimensionamento local.

## Revisão de consistência, design e layout

Foi feita uma leitura estática de `Theme.qml`, `Colors.qml`, `shell.qml` e dos QML em `modules/` e `widgets/`. A interface tem uma base coesa: usa as cores dinâmicas do Matugen, superfícies escuras, bordas discretas e uma hierarquia de formas razoavelmente estável. Popups pequenos tendem a usar raio 12 e margens de 14–16 px; janelas centrais usam raio 18 e margem interna de 20 px; cards ficam perto de raio 9–10. As diferenças de tamanho entre launcher, seletor local e Wallhaven parecem adequadas ao conteúdo e não precisam ser uniformizadas à força.

### Ajustes que valem a pena

1. **Checar o layout no monitor menor e em resoluções estreitas.** A barra posiciona as áreas esquerda, central e direita de forma independente (`modules/Bar.qml`), sem uma regra adaptativa para esconder ou compactar módulos quando não há espaço. A área de mídia pode chegar a 350 px. Isso cria risco de colisão em telas estreitas ou quando a bandeja tem muitos ícones; a leitura do QML não confirma uma colisão numa resolução específica. Alguns popups também têm dimensões fixas — por exemplo `SystemUsagePopup.qml` (380×540), `MediaPopup.qml` (360×210) e `CalendarPopup.qml` (328×370) — e são abertos abaixo da barra sem ajuste vertical. `ArchMenu.qml` cresce conforme o conteúdo; a lista de Wi-Fi tem altura máxima e rolagem, mas a lista Bluetooth e o menu completo não têm um limite equivalente visível. **Recomendação:** validar primeiro na resolução efetivamente usada e na menor tela conectada; se houver corte, limitar altura e tornar o conteúdo rolável e posicionar o popup para cima quando faltar espaço.

2. **Escolher um idioma para todos os textos da interface.** Há textos em português nos menus rápidos, launcher e seletor local, enquanto Wallhaven e System Usage usam títulos, estados e instruções em inglês. Essa mistura é perceptível e não parece necessária para o funcionamento. **Recomendação:** como a maior parte da UI já está em português, traduzir os rótulos e mensagens restantes; uma futura configuração de idioma pode substituir textos fixos se houver intenção de suportar mais idiomas.

3. **Definir e documentar as fontes de ícones.** A configuração usa ligaduras da Material Symbols em diversos módulos e ícones da JetBrainsMono Nerd Font em outros, como brilho, workspaces e partes da barra. `Theme.qml` define JetBrainsMono como fonte geral, mas algumas áreas usam Material Symbols explicitamente. A mistura pode ser intencional, mas exige ambas as fontes instaladas e pode produzir tamanhos/pesos visuais diferentes. **Recomendação:** escolher uma família principal de ícones ou documentar a dependência das duas, centralizar tamanhos comuns no tema e definir `font.family` também nos textos que hoje dependem da fonte padrão do sistema.

4. **Centralizar poucos tokens visuais que realmente se repetem.** Raio de painel, raio de campo, largura/transparência de borda, scrim e fundos de legenda de imagem aparecem como números e cores literais em vários arquivos (`ApplicationLauncher.qml`, `Wallpaper.qml`, `Wallhaven.qml`, `ArchMenu.qml` e popups). Isso dificulta ajustar a aparência globalmente e pode causar pequenas diferenças com o tempo. **Recomendação:** adicionar tokens semânticos para superfícies de popup/modal, campos e scrim em `Theme.qml`, e usá-los conforme os componentes forem editados. Não vale transformar cada espaçamento isolado em token.

5. **Reaproveitar o carregamento de paleta do Wlogout quando o fluxo permitir.** O Wlogout usado pelo `shell.qml` recebe as cores de `Theme.qml`, enquanto `widgets/Wlogout.qml` mantém um segundo `FileView`/`JsonAdapter` com valores de fallback para a entrada standalone. As paletas atuais são visualmente alinhadas; o risco é uma mudança futura ser aplicada a uma fonte e esquecida na outra. **Recomendação:** avaliar um helper de paleta compartilhado que continue funcionando no modo standalone ou manter explicitamente ambos os pontos sincronizados.

### Variações que parecem intencionais

- O seletor de wallpapers locais e o Wallhaven compartilham estrutura, paleta, bordas e raio; o Wallhaven é maior porque mostra metadados e oferece busca/paginação. O overlay de título das imagens usa preto e texto claro para preservar legibilidade sobre fotos, portanto não é por si só uma inconsistência de tema.
- O Wlogout tem composição própria de grade e fundo com blur, diferente dos popups da barra; não é necessário forçar o mesmo raio ou espaçamento das outras janelas.
- Os tamanhos de fonte variam entre relógio, labels, título e ícone. O problema observado não é a existência de tamanhos diferentes, e sim haver valores recorrentes fora de `Theme.qml` sem uma distinção semântica clara.

Esta avaliação é estrutural: sem capturas de tela ou a resolução/tamanho dos monitores, problemas de colisão e equilíbrio visual são riscos identificados pelo layout declarativo, não defeitos confirmados em execução.

## Vale a pena priorizar

### 1. Reduzir o polling de brilho

`services/Brightness.qml` consulta o arquivo sysfs de brilho por meio de um `Process` a cada **200 ms** enquanto o backlight é suportado. Isso permite até cinco leituras externas por segundo, mesmo quando o valor não muda. O serviço impede leituras simultâneas e suspende a consulta brevemente durante ajustes feitos pela própria UI, mas ainda há inicializações frequentes de processo.

**Recomendação:** aumentar o intervalo para algo entre **500 ms e 1 s** e observar se a atualização externa (por exemplo, teclas Fn) continua responsiva. Um intervalo maior reduz a frequência de consultas com um possível pequeno atraso visual. Como alternativa futura, usar uma fonte de eventos do sistema, caso exista uma integração adequada para o backlight no ambiente.

**Retorno esperado:** redução modesta, porém concreta, de processos ociosos. Não há medição que sustente uma economia relevante de CPU ou RAM.

### 2. Dividir `modules/ArchMenu.qml` em partes menores

O arquivo tem cerca de 1.650 linhas e reúne interface do menu, operações e parsing de `nmcli`/`bluetoothctl`, estado de Wi-Fi e Bluetooth e ações de sessão. O menu atual limita boa parte das atualizações ao período em que está aberto: há uma atualização em intervalos de 15 s e, durante a busca Bluetooth, consultas de dispositivos conhecidos a cada 1,5 s.

**Recomendação:** separar primeiro responsabilidades em componentes/serviços sem alterar o comportamento: por exemplo, UI de Wi-Fi, UI de Bluetooth e ações de sessão. Manter a implementação atual funcionando entre etapas facilita revisar regressões.

**Retorno esperado:** melhora de leitura e manutenção; provável redução de duplicação e acoplamento. Não se espera ganho de desempenho relevante apenas por dividir o QML.

### 3. Considerar APIs nativas para Wi-Fi e Bluetooth

O menu usa comandos de `nmcli` e `bluetoothctl` para consultar e alterar estado. O Quickshell 0.3.1 documenta APIs próprias para dispositivos e redes Wi-Fi e para adaptadores/dispositivos Bluetooth. Migrar consultas para objetos reativos pode eliminar parte do polling e do parsing de texto, mas a paridade com os recursos existentes (redes, conexão com senha, pareamento, dispositivos conhecidos e estados) precisa ser preservada.

**Recomendação:** fazer um protótipo por subsistema depois de separar a lógica de `ArchMenu.qml`; manter os comandos atuais até validar o mesmo conjunto de operações e estados. Tratar a troca como projeto de médio porte, não como otimização rápida.

Documentação: [NetworkDevice](https://quickshell.org/docs/v0.3.1/types/Quickshell.Networking/NetworkDevice/), [WifiNetwork](https://quickshell.org/docs/v0.3.1/types/Quickshell.Networking/WifiNetwork/), [WifiDevice](https://quickshell.org/docs/v0.3.1/types/Quickshell.Networking/WifiDevice/), [Bluetooth](https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/Bluetooth/) e [BluetoothAdapter](https://quickshell.org/docs/v0.3.1/types/Quickshell.Bluetooth/BluetoothAdapter/).

## Melhorias úteis, mas sem urgência

### 4. Compartilhar a apresentação dos OSDs

`widgets/VolumeOSD.qml` e `widgets/BrightnessOSD.qml` repetem boa parte do layout, dimensões e barra de nível. Os gatilhos, porém, são diferentes: volume reage ao serviço de áudio e brilho observa o serviço de backlight.

**Recomendação:** se esses widgets continuarem recebendo mudanças visuais, extrair somente a apresentação para um componente configurável e preservar os gatilhos separados. Se não houver mudanças planejadas, a duplicação atual é simples o bastante para não justificar uma refatoração imediata.

**Retorno esperado:** menos código de layout para manter; praticamente nenhum ganho de runtime.

### 5. Trocar a consulta periódica de perfil de energia por API nativa

`services/PowerProfiles.qml` consulta `powerprofilesctl get` a cada 30 s e após mudanças feitas pelo próprio menu. A documentação do Quickshell fornece `UPower.PowerProfiles.profile` como propriedade que representa o perfil atual e pode ser alterada quando o serviço UPower está disponível.

**Recomendação:** considerar a migração se a configuração já depender de UPower e se o estado “indisponível” puder ser representado corretamente. É uma limpeza e melhora de reatividade, mas as consultas atuais são poucas e não indicam um problema de desempenho.

Documentação: [UPower PowerProfiles](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.UPower/PowerProfiles/).

### 6. Limitar o cache de páginas do Wallhaven apenas se o uso mostrar necessidade

`widgets/Wallhaven.qml` guarda respostas JSON das páginas visitadas durante a sessão e limpa o cache ao fechar ou iniciar outra busca. Isso acelera a navegação de volta, mas pode crescer conforme o usuário percorre muitas páginas.

**Recomendação:** não priorizar sem observar consumo de memória ou sessões longas. Se necessário, manter uma janela pequena de páginas próximas à atual, incluindo as páginas pré-carregadas.

## Não priorizar agora

- **C++ para o application launcher:** o catálogo observado tem aproximadamente 92 arquivos `.desktop`; a busca acontece sobre uma lista limitada e a exibição usa `ListView`. Não há evidência de custo suficiente para justificar uma extensão nativa, que acrescentaria complexidade de compilação e manutenção. Reavaliar apenas com medições que mostrem atraso perceptível ou uso alto de memória.
- **Otimização de RAM do launcher:** o estado de uso guarda apenas contagem e horário do último uso por aplicação. Não há indicação de que a lista ou esse cache causem pressão de memória.
- **Agrupar todos os comandos de rede em um único processo:** isso pode reduzir inicializações no momento de abrir o menu, mas não ataca a principal questão estrutural e aumenta o acoplamento do parsing. Separar responsabilidades e avaliar APIs nativas é um caminho mais sustentável.
- **Criar serviço compartilhado de ações de sessão imediatamente:** `ArchMenu` e `BatteryMenu` possuem funções de confirmar ações semelhantes, mas usam comandos distintos para logout, reboot e shutdown. Só centralizar se primeiro for definida uma semântica comum para esses comandos e seus erros.
- **Unificar os dois OSDs por performance:** a extração pode reduzir duplicação visual, mas não reduz trabalho contínuo ou consumo perceptível por si só.

## Sugestões antigas já resolvidas ou desatualizadas

- **Regras de ícone/estado da bateria:** `modules/Battery.qml` e `modules/BatteryMenu.qml` já importam `services/BatteryRules.js`.
- **Cor de destaque do relógio:** `modules/Clock.qml` já centraliza a regra em `accentColor`.
- **Container repetido da barra:** existe `modules/ModuleGroup.qml`, que consome valores compartilhados de `Theme.qml`; a recomendação antiga para esse ponto não é mais necessária.
- **Limites de posição dos popups:** `Bar.qml` fornece `positionProvider` para os menus de Arch e bateria; os demais popups também recebem seu provedor de posição.
- **Suposto polling de CPU/memória a cada 2 s via `free`:** o código atual está em `services/SystemStats.qml`, lê `/proc/stat` e `/proc/meminfo` em uma chamada `cat` a cada 5 s. Esse custo parece baixo para priorizar.

## Ordem sugerida

1. Validar barra e popups na menor resolução/tela usada; corrigir apenas cortes ou colisões confirmados.
2. Uniformizar o idioma dos textos visíveis.
3. Ajustar o intervalo do polling de brilho e conferir a responsividade percebida.
4. Dividir `ArchMenu.qml` por responsabilidade, mantendo o comportamento atual.
5. Centralizar os tokens visuais repetidos e documentar as fontes de ícones durante futuras alterações de UI.
6. Prototipar a API nativa de Wi-Fi ou Bluetooth e comparar cobertura funcional antes de migrar.
7. Fazer extrações de OSD e PowerProfiles quando esses arquivos já forem receber mudanças.
8. Reavaliar o cache do Wallhaven e o launcher apenas se surgirem sintomas mensuráveis.
