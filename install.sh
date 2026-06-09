#!/usr/bin/env bash
# =============================================================================
# install.sh — Dotfiles installer for Arch Linux
# =============================================================================

set -e  # Abort on error

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}==> ${RESET}${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}  ✓ ${RESET}$*"; }
warn()    { echo -e "${YELLOW}${BOLD}  ! ${RESET}$*"; }
die()     { echo -e "${RED}${BOLD}  ✗ ERROR: ${RESET}$*"; exit 1; }

# -----------------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------------
[[ $EUID -eq 0 ]] && die "Don't run this script as root."
command -v pacman &>/dev/null || die "This script requires Arch Linux (pacman not found)."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Avisos não-fatais acumulados durante a instalação
WARNINGS=()

# -----------------------------------------------------------------------------
# Packages
# -----------------------------------------------------------------------------
PACMAN_PKGS=(
    hyprland
    hyprsunset
    hypridle
    hyprlock
    hyprpolkitagent
    btop
    fastfetch
    brightnessctl
    power-profiles-daemon
    mako
    cliphist
    wl-clipboard
    grim
    slurp
    easyeffects
    rnnoise
    udiskie
    udisks2
    nemo
    nemo-fileroller
    gnome-keyring
    gvfs
    steam
    kitty
    networkmanager
    network-manager-applet
    blueman
    ttf-jetbrains-mono-nerd
    pipewire
    pipewire-pulse
    wireplumber
    xdg-desktop-portal-hyprland
    qt5ct
    qt6ct
    kvantum
    kvantum-qt5
)

AUR_PKGS=(
    quickshell
    awww
    vesktop-bin
    zen-browser-bin
    deepfilternet-demos-git
    lsp-plugins
    calf
)

# -----------------------------------------------------------------------------
# 1. Install paru (AUR helper)
# -----------------------------------------------------------------------------
install_paru() {
    if command -v paru &>/dev/null; then
        success "paru already installed, skipping."
        return
    fi

    info "Installing paru..."
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    success "paru installed."
}

# -----------------------------------------------------------------------------
# 2. Install pacman packages
# -----------------------------------------------------------------------------
install_pacman_pkgs() {
    if [[ ${#PACMAN_PKGS[@]} -eq 0 ]]; then
        warn "No pacman packages defined, skipping."
        return
    fi

    info "Installing pacman packages..."
    sudo pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"
    success "pacman packages installed."
}

# -----------------------------------------------------------------------------
# 3. Install AUR packages
# -----------------------------------------------------------------------------
install_aur_pkgs() {
    if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
        warn "No AUR packages defined, skipping."
        return
    fi

    info "Installing AUR packages..."
    paru -S --noconfirm --needed "${AUR_PKGS[@]}"
    success "AUR packages installed."
}

# -----------------------------------------------------------------------------
# 4. Copy dotfiles
# -----------------------------------------------------------------------------
copy_dotfiles() {
    info "Copying dotfiles..."

    # .config
    if [[ -d "$DOTFILES_DIR/.config" ]]; then
        cp -r "$DOTFILES_DIR/.config/." "$HOME/.config/"
        success ".config copied to $HOME."
    else
        warn ".config directory not found in $DOTFILES_DIR, skipping."
    fi

    # Pictures
    if [[ -d "$DOTFILES_DIR/Pictures" ]]; then
        cp -r "$DOTFILES_DIR/Pictures/." "$HOME/Pictures/"
        success "Pictures copied to $HOME."
    else
        warn "Pictures directory not found in $DOTFILES_DIR, skipping."
    fi
}

# -----------------------------------------------------------------------------
# 5. Install Colloid Icon Theme (via GitHub)
# -----------------------------------------------------------------------------
install_colloid_icons() {
    info "Installing Colloid Icon Theme..."

    local tmp
    tmp=$(mktemp -d)

    if ! git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme.git "$tmp/colloid-icons"; then
        WARNINGS+=("Colloid Icon Theme: falha ao clonar o repositório. Instale manualmente depois.")
        warn "Could not clone Colloid Icon Theme, skipping."
        rm -rf "$tmp"
        return
    fi

    if ! bash "$tmp/colloid-icons/install.sh"; then
        WARNINGS+=("Colloid Icon Theme: install script falhou. Instale manualmente depois.")
        warn "Colloid install script failed, skipping."
        rm -rf "$tmp"
        return
    fi

    rm -rf "$tmp"
    success "Colloid Icon Theme installed to ~/.local/share/icons."
}

# -----------------------------------------------------------------------------
# 6. Install Kvantum theme (AUR, non-fatal)
# -----------------------------------------------------------------------------
install_kvantum_theme() {
    info "Installing Kvantum Colloid theme..."

    # kvantum já está no PACMAN_PKGS, então só tenta o tema via AUR
    local kvantum_pkg="colloid-kde-theme-git"

    if paru -Si "$kvantum_pkg" &>/dev/null; then
        if paru -S --noconfirm --needed "$kvantum_pkg"; then
            success "Kvantum Colloid theme installed."
        else
            WARNINGS+=("Kvantum theme ($kvantum_pkg): falha no AUR. Rode 'paru -S $kvantum_pkg' manualmente depois.")
            warn "Kvantum theme install failed, skipping."
        fi
    else
        WARNINGS+=("Kvantum theme ($kvantum_pkg): não encontrado no AUR. Instale o tema Kvantum manualmente depois.")
        warn "$kvantum_pkg not found on AUR — install the Kvantum theme manually later."
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo -e "\n${BOLD}Dotfiles Installer${RESET}\n"

    install_paru
    install_pacman_pkgs
    install_aur_pkgs
    copy_dotfiles
    install_colloid_icons
    install_kvantum_theme

    echo -e "\n${GREEN}${BOLD}✓ Instalação completa!${RESET}"

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}${BOLD}Pendências manuais:${RESET}"
        for w in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}•${RESET} $w"
        done
    fi

    echo -e "\n${YELLOW}  ℹ Algumas mudanças serão aplicadas somente após logout/reboot.${RESET}\n"
}

main "$@"