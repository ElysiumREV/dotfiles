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

PACMAN_PKGS=(
  hyprland
  hyprsunset
  hypridle
  hyprlock
  hyprpolkitagent
  btop
  fastfetch
  brightnessctl
  powerprofilesctl
  mako
  cliphist
  wl-clipboard
  grim
  slurp
  easyeffects
  udiskie
  udisks2
  nemo
  nemo-fileroller
  gnome-libsecret
  gvfs
  steam
  kitty
  networkmanager
  network-manager-applet
  blueman
  ttf-jetbrains-mono-nerd
)

AUR_PKGS=(
  quickshell
  awww
  vesktop
  zen-browser
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
        cp -r "$DOTFILES_DIR/.config" "$HOME/"
        success ".config copied to $HOME."
    else
        warn ".config directory not found in $DOTFILES_DIR, skipping."
    fi
 
    # Pictures
    if [[ -d "$DOTFILES_DIR/Pictures" ]]; then
        cp -r "$DOTFILES_DIR/Pictures" "$HOME/"
        success "Pictures copied to $HOME."
    else
        warn "Pictures directory not found in $DOTFILES_DIR, skipping."
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
 
    echo -e "\n${GREEN}${BOLD}All done!${RESET} Restart your session to apply changes.\n"
}
 
main "$@"
