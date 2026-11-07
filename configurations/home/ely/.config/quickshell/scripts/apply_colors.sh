#!/usr/bin/env bash
# Generates the Matugen palette from a wallpaper and propagates it to applications.
# Matugen's config.toml only generates files; all hooks live here.
# Only Matugen is required; every integration is optional and, if missing or
# failing, just logs a warning without interrupting the others.
set -u

# Paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
DEFAULT_WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
KDE_CONFIG="$XDG_CONFIG_HOME/kde-material-you-colors/config.conf"
KDE_WRAPPER="$XDG_CONFIG_HOME/matugen/templates/kde/kde-material-you-colors-wrapper.sh"
GTK_RELOAD="$XDG_CONFIG_HOME/matugen/post-hook-scripts/gtk-themes-reload.sh"
COLORS_JSON="$XDG_STATE_HOME/quickshell/generated/colors.json"
# Usage: apply_colors.sh <wallpaper> [dark|light]   (default: dark, or $QS_COLOR_MODE)
MODE="${2:-${QS_COLOR_MODE:-dark}}"

log()  { echo "[Colors] $*"; }
warn() { echo "[Warning] $*" >&2; }
fail() { echo "[Error] $*" >&2; exit 1; }

# Runs an optional command; failures become warnings and never abort the script.
optional() {
    local label="$1"
    shift
    "$@" >/dev/null 2>&1 || warn "$label failed or is unavailable."
}

case "$MODE" in
    dark|light) ;;
    *) warn "Unknown color mode '$MODE'; using dark."; MODE=dark ;;
esac

log "Starting color update ($MODE)..."

# 1. Symlink to the current wallpaper
WALLPAPER_PATH="${1:-}"
if [ -z "$WALLPAPER_PATH" ] || [ ! -f "$WALLPAPER_PATH" ]; then
    fail "No valid wallpaper path provided."
fi

WALLPAPER_LINK="$DEFAULT_WALLPAPER_DIR/.current-wallpaper.png"
# Resolve symlinks so passing the current-wallpaper link itself (mode switch) never makes it point at itself.
WALLPAPER_PATH="$(readlink -f -- "$WALLPAPER_PATH")"

log "Updating wallpaper symlink..."
if ! mkdir -p "$DEFAULT_WALLPAPER_DIR" || ! ln -sfn "$WALLPAPER_PATH" "$WALLPAPER_LINK"; then
    fail "Could not update the wallpaper symlink."
fi

# 2. Matugen palette (the only required step)
command -v matugen >/dev/null 2>&1 || fail "Matugen is not installed."

log "Generating palette with Matugen ($MODE)..."
matugen image "$WALLPAPER_LINK" --mode "$MODE" --source-color-index 0 \
    || fail "Matugen failed to generate colors."

# Forces Quickshell to reload the colors
[ -f "$COLORS_JSON" ] && touch "$COLORS_JSON"

# 3. Kitty theme
KITTY_THEME="$XDG_CONFIG_HOME/kitty/themes/Matugen.conf"
if [ -f "$KITTY_THEME" ]; then
    log "Syncing Kitty theme..."
    optional "Copying the Kitty theme" cp "$KITTY_THEME" "$XDG_CONFIG_HOME/kitty/current-theme.conf"
fi

# 4. GTK color-scheme preference. This must happen before the KDE wrapper, which
# reads it to pick the dark/light variant (running it after lags one switch behind).
if [ -f "$GTK_RELOAD" ]; then
    optional "GTK reload" sh "$GTK_RELOAD" "$MODE"
fi

# 5. KDE/Qt via kde-material-you-colors (optional)
if [ -f "$KDE_WRAPPER" ]; then
    SCHEME_VARIANT=""
    if [ -f "$KDE_CONFIG" ]; then
        SCHEME_VARIANT=$(grep 'scheme_variant' "$KDE_CONFIG" | head -n 1 | awk -F= '{print $2}' | xargs)
    else
        warn "kde-material-you-colors config not found: $KDE_CONFIG"
    fi
    SCHEME_VARIANT="${SCHEME_VARIANT:-scheme-tonal-spot}"

    log "Applying colors to KDE/Qt (variant: $SCHEME_VARIANT)..."
    QS_COLOR_MODE="$MODE" bash "$KDE_WRAPPER" --scheme-variant "$SCHEME_VARIANT" \
        || warn "KDE wrapper exited with an error."
else
    warn "kde-material-you-colors wrapper not found; skipping KDE/Qt."
fi

# 6. Reloading applications
log "Updating applications..."

if command -v kitty >/dev/null 2>&1; then
    kitty @ set-colors --all "$KITTY_THEME" >/dev/null 2>&1 \
        || optional "Kitty reload" kitty +kitten themes --reload-in=all Matugen &
fi

# Neovim reloads its theme on SIGUSR1; -x avoids matching other processes.
if command -v pkill >/dev/null 2>&1; then
    pkill -SIGUSR1 -x nvim >/dev/null 2>&1 || true
fi

if command -v pywalfox >/dev/null 2>&1; then
    # Pywalfox keeps its own dark/light setting, so Firefox stays dark unless told otherwise.
    ( optional "Pywalfox mode" pywalfox "$MODE"; optional "Pywalfox update" pywalfox update ) &
fi

if command -v spotifast >/dev/null 2>&1; then
    optional "Spotifast theme reload" spotifast reload-themes &
fi

wait
log "Done."
exit 0
