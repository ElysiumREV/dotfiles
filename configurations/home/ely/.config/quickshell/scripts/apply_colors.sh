#!/usr/bin/env bash

# Configurações de caminhos
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
DEFAULT_WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
KDE_CONFIG="$XDG_CONFIG_HOME/kde-material-you-colors/config.conf"
KDE_WRAPPER="$XDG_CONFIG_HOME/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"

echo "[Colors] Iniciando processo de atualização de cores..."

# 1. Lidar com o Link Simbólico
WALLPAPER_PATH="$1"
if [ -z "$WALLPAPER_PATH" ]; then
    echo "[Erro] Nenhum caminho de wallpaper fornecido."
    exit 1
fi

echo "[Colors] Atualizando link simbólico do wallpaper..."
mkdir -p "$DEFAULT_WALLPAPER_DIR"
ln -sfn "$WALLPAPER_PATH" "$DEFAULT_WALLPAPER_DIR/.current-wallpaper.png"

# 2. Gerar cores com Matugen
WALLPAPER_LINK="$DEFAULT_WALLPAPER_DIR/.current-wallpaper.png"

echo "[Colors] Gerando paleta com Matugen..."
matugen image "$WALLPAPER_LINK" --mode dark --source-color-index 0
if [ $? -ne 0 ]; then
    echo "[Erro] Matugen falhou ao gerar cores."
    exit 1
fi

# Forçar recarga do Quickshell
if [ -f "$COLORS_JSON" ]; then
    touch "$COLORS_JSON"
fi

# 3. Sincronizar Tema do Kitty (CORREÇÃO AQUI)
if [ -f "$XDG_CONFIG_HOME/kitty/themes/Matugen.conf" ]; then
    echo "[Colors] Sincronizando tema do Kitty..."
    cp "$XDG_CONFIG_HOME/kitty/themes/Matugen.conf" "$XDG_CONFIG_HOME/kitty/current-theme.conf"
fi

# 4. Determinar a variante de esquema do KDE
SCHEME_VARIANT=$(grep 'scheme_variant' "$KDE_CONFIG" | awk -F= '{print $2}' | xargs)
if [ -z "$SCHEME_VARIANT" ]; then
    SCHEME_VARIANT="scheme-tonal-spot"
fi
echo "[Colors] Variante KDE detectada: $SCHEME_VARIANT"

# 5. Aplicar ao KDE via Wrapper
if [ -f "$KDE_WRAPPER" ]; then
    echo "[Colors] Aplicando cores ao KDE/Qt..."
    bash "$KDE_WRAPPER" --scheme-variant "$SCHEME_VARIANT"
else
    echo "[Erro] Wrapper do kde-material-you-colors não encontrado em $KDE_WRAPPER"
fi

# 6. Post-Hooks Unificados
echo "[Colors] Atualizando aplicativos..."

# Kitty reload
if command -v kitty >/dev/null; then
    # Usamos o comando de recarga do kitty
    kitty @ set-colors --all Matugen 2>/dev/null || kitty +kitten themes --reload-in=all Matugen &
fi

# GTK
if [ -f "$XDG_CONFIG_HOME/matugen/post-hook-scripts/gtk-themes-reload.sh" ]; then
    sh "$XDG_CONFIG_HOME/matugen/post-hook-scripts/gtk-themes-reload.sh" dark &
fi

# Mako
if command -v makoctl >/dev/null; then
    makoctl reload &
fi

# Neovim
pkill -SIGUSR1 nvim &

# Pywalfox
if command -v pywalfox >/dev/null; then
    pywalfox update &
fi

echo "[Colors] Processo concluído com sucesso!"
exit 0
