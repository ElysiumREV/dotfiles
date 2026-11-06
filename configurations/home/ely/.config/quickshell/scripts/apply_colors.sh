#!/usr/bin/env bash
# Gera a paleta Matugen a partir de um wallpaper e propaga para os aplicativos.
# O config.toml do Matugen só gera os arquivos; todos os hooks ficam aqui.
# Só o Matugen é obrigatório; cada integração é opcional e, se faltar ou
# falhar, apenas registra um aviso sem interromper as demais.
set -u

# Configurações de caminhos
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
DEFAULT_WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
KDE_CONFIG="$XDG_CONFIG_HOME/kde-material-you-colors/config.conf"
KDE_WRAPPER="$XDG_CONFIG_HOME/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
GTK_RELOAD="$XDG_CONFIG_HOME/matugen/post-hook-scripts/gtk-themes-reload.sh"
COLORS_JSON="$XDG_STATE_HOME/quickshell/generated/colors.json"
MODE="${QS_COLOR_MODE:-dark}"

log()  { echo "[Colors] $*"; }
warn() { echo "[Aviso] $*" >&2; }
fail() { echo "[Erro] $*" >&2; exit 1; }

# Executa um comando opcional; falhas viram aviso e nunca abortam o script.
optional() {
    local label="$1"
    shift
    "$@" >/dev/null 2>&1 || warn "$label falhou ou não está disponível."
}

log "Iniciando processo de atualização de cores..."

# 1. Link simbólico do wallpaper atual
WALLPAPER_PATH="${1:-}"
if [ -z "$WALLPAPER_PATH" ] || [ ! -f "$WALLPAPER_PATH" ]; then
    fail "Nenhum caminho de wallpaper válido fornecido."
fi

WALLPAPER_LINK="$DEFAULT_WALLPAPER_DIR/.current-wallpaper.png"

log "Atualizando link simbólico do wallpaper..."
if ! mkdir -p "$DEFAULT_WALLPAPER_DIR" || ! ln -sfn "$WALLPAPER_PATH" "$WALLPAPER_LINK"; then
    fail "Não foi possível atualizar o link simbólico do wallpaper."
fi

# 2. Paleta Matugen (único passo obrigatório)
command -v matugen >/dev/null 2>&1 || fail "Matugen não está instalado."

log "Gerando paleta com Matugen ($MODE)..."
matugen image "$WALLPAPER_LINK" --mode "$MODE" --source-color-index 0 \
    || fail "Matugen falhou ao gerar cores."

# Força o Quickshell a recarregar as cores
[ -f "$COLORS_JSON" ] && touch "$COLORS_JSON"

# 3. Tema do Kitty
KITTY_THEME="$XDG_CONFIG_HOME/kitty/themes/Matugen.conf"
if [ -f "$KITTY_THEME" ]; then
    log "Sincronizando tema do Kitty..."
    optional "Cópia do tema do Kitty" cp "$KITTY_THEME" "$XDG_CONFIG_HOME/kitty/current-theme.conf"
fi

# 4. KDE/Qt via kde-material-you-colors (opcional)
if [ -f "$KDE_WRAPPER" ]; then
    SCHEME_VARIANT=""
    if [ -f "$KDE_CONFIG" ]; then
        SCHEME_VARIANT=$(grep 'scheme_variant' "$KDE_CONFIG" | head -n 1 | awk -F= '{print $2}' | xargs)
    else
        warn "Config do kde-material-you-colors não encontrada: $KDE_CONFIG"
    fi
    SCHEME_VARIANT="${SCHEME_VARIANT:-scheme-tonal-spot}"

    log "Aplicando cores ao KDE/Qt (variante: $SCHEME_VARIANT)..."
    bash "$KDE_WRAPPER" --scheme-variant "$SCHEME_VARIANT" \
        || warn "Wrapper do KDE terminou com erro."
else
    warn "Wrapper do kde-material-you-colors não encontrado; pulando KDE/Qt."
fi

# 5. Recarga dos aplicativos
log "Atualizando aplicativos..."

if command -v kitty >/dev/null 2>&1; then
    kitty @ set-colors --all "$KITTY_THEME" >/dev/null 2>&1 \
        || optional "Recarga do Kitty" kitty +kitten themes --reload-in=all Matugen &
fi

if [ -f "$GTK_RELOAD" ]; then
    optional "Recarga do GTK" sh "$GTK_RELOAD" "$MODE" &
fi

# Neovim recarrega o tema ao receber SIGUSR1; -x evita casar outros processos.
if command -v pkill >/dev/null 2>&1; then
    pkill -SIGUSR1 -x nvim >/dev/null 2>&1 || true
fi

if command -v pywalfox >/dev/null 2>&1; then
    optional "Atualização do Pywalfox" pywalfox update &
fi

if command -v spotifast >/dev/null 2>&1; then
    optional "Recarga de temas do Spotifast" spotifast reload-themes &
fi

wait
log "Processo concluído."
exit 0
