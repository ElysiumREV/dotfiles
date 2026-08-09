#!/usr/bin/env bash

set -e # Abort on error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info() { echo -e "${CYAN}${BOLD}==> ${RESET}${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}  ✓ ${RESET}$*"; }
warn() { echo -e "${YELLOW}${BOLD}  ! ${RESET}$*"; }
die() {
  echo -e "${RED}${BOLD}  ✗ ERROR: ${RESET}$*"
  exit 1
}

check_arch() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" != "arch" ]]; then
      die "Este script é exclusivo para Arch Linux. Distribuição detectada: $ID."
    fi
  elif [[ ! -f /etc/arch-release ]]; then
    die "Este script é exclusivo para Arch Linux. Não foi possível confirmar a distribuição."
  fi
}

[[ $EUID -eq 0 ]] && die "Não rode o script com sudo ou como root.\nO script cuida dessa parte pedindo sudo quando necessário."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_arch
info "Arch Linux confirmado."

WARNINGS=()

PACMAN_PKGS=(
    # Base / Utilities
    git
    base-devel
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    vim
    neovim

    # Security / Network / Services
    wpa_supplicant
    ufw
    cups
    cups-pk-helper
    system-config-printer

    # System tools
    btop
    fastfetch
    brightnessctl
    power-profiles-daemon
    udiskie
    udisks2
    gnome-keyring
    gvfs

    # Desktop environment
    quickshell
    hyprland
    hyprsunset
    hypridle
    hyprlock
    hyprpicker
    hyprpolkitagent
    mako
    cliphist
    wl-clipboard
    grim
    slurp

    # File manager
    nemo
    nemo-fileroller
    ffmpegthumbnailer

    # Audio
    easyeffects
    noise-suppression-for-voice
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    gst-plugin-pipewire
    gst-plugins-base-libs
    pavucontrol
    playerctl
    mpd

    # Network / Bluetooth
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman

    # Graphics / OpenCL
    ocl-icd
    opencl-icd-loader
    vulkan-tools
    glfw

    # Gaming
    steam
    gamescope
    mangohud
    umu-launcher
    protontricks
    winetricks
    lutris
    goverlay

    # Gaming libraries
    openal
    libva
    libjpeg
    giflib
    mpg123
    alsa-plugins

    # 32-bit gaming libraries
    lib32-mangohud
    lib32-alsa-plugins
    lib32-openal
    lib32-libva
    lib32-libjpeg-turbo
    lib32-mpg123
    lib32-ocl-icd
    lib32-giflib
    lib32-gtk3

    # Desktop applications
    firefox
    mpv
    kitty
    spotify-launcher
    kate
    obsidian
    zed
    bitwarden
    discord
    qbittorrent
    partitionmanager

    # GTK / Qt / Theming
    xdg-desktop-portal-hyprland
    qt5ct
    qt6ct
    kvantum
    kvantum-qt5
    adw-gtk-theme
    nwg-look
    papirus-icon-theme

    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-material-symbols-variable
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    ttf-liberation
)

AUR_PKGS=(
  awww # (swww has been renamed)
  # vesktop-bin
  zsh-theme-powerlevel10k-git
  opencode
  vicinae-bin
  hayase-desktop-bin
  stremio-enhanced-bin
)

# Pacotes que compilam do source — instalação opcional
HEAVY_PKGS=(
  "deepfilternet-demos-git"
  "lsp-plugins"
  "calf"
)

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

install_required_packages() {
  install_paru
}

install_system_packages() {
  if [[ ${#PACMAN_PKGS[@]} -eq 0 ]]; then
    warn "No pacman packages defined, skipping."
    return
  fi

  info "Installing pacman packages..."
  sudo pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"
  success "pacman packages installed."
}

install_extra_packages() {
  if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
    warn "No AUR packages defined, skipping."
    return
  fi

  echo -e "\n${YELLOW}${BOLD}Pacotes AUR:${RESET}"
  for pkg in "${AUR_PKGS[@]}"; do
    echo -e "  ${CYAN}•${RESET} $pkg"
  done

  echo -e "\n${BOLD}Deseja instalar os pacotes AUR agora? [y/N]${RESET} "
  read -r response
  if [[ "${response,,}" != "y" ]]; then
    WARNINGS+=("Pacotes AUR não instalados. Rode manualmente: paru -S ${AUR_PKGS[*]}")
    warn "Pacotes AUR ignorados."
    return
  fi

  info "Installing AUR packages..."
  if ! paru -S --noconfirm --needed "${AUR_PKGS[@]}"; then
    WARNINGS+=("Falha ao instalar um ou mais pacotes AUR. Rode manualmente: paru -S ${AUR_PKGS[*]}")
    warn "Falha na instalação de pacotes AUR."
    return
  fi
  success "AUR packages installed."
}

install_sddm_if_needed() {
  local current_dm_service=""
  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    current_dm_service=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)" .service)
  fi

  if [[ -n "$current_dm_service" && "$current_dm_service" != "sddm" ]]; then
    info "Removing previous display manager: $current_dm_service"
    sudo systemctl disable "${current_dm_service}.service" || true
    sudo pacman -Rns --noconfirm "$current_dm_service" || true
  fi

  info "Installing SDDM..."
  sudo pacman -S --noconfirm --needed sddm

  sudo systemctl enable sddm
  success "SDDM installed and enabled."
}

install_sddm_theme() {
  info "Installing SilentSDDM theme..."

  local tmp
  tmp=$(mktemp -d)

  git clone https://github.com/uiriansan/SilentSDDM.git "$tmp/SilentSDDM"

  if [[ -f "$tmp/SilentSDDM/install.sh" ]]; then
    chmod +x "$tmp/SilentSDDM/install.sh"

    (
      cd "$tmp/SilentSDDM"
      ./install.sh
    )

    success "SilentSDDM theme installed."
  else
    warn "SilentSDDM install.sh not found, skipping."
    WARNINGS+=("SilentSDDM theme installation failed.")
  fi

  rm -rf "$tmp"
}

copy_dotfiles() {
  info "Copying dotfiles..."

  # Source directory for dotfiles (from configurations/home/ely)
  DOTFILES_SOURCE="$DOTFILES_DIR/configurations/home/ely"

  # .config
  if [[ -d "$DOTFILES_SOURCE/.config" ]]; then
    cp -r "$DOTFILES_SOURCE/.config/." "$HOME/.config/"
    success ".config copied to $HOME."
  else
    warn ".config directory not found in $DOTFILES_SOURCE, skipping."
  fi

  # Zsh configuration

  if [[ -f "$DOTFILES_SOURCE/.zshrc" ]]; then
      cp "$DOTFILES_SOURCE/.zshrc" "$HOME/.zshrc"
      success ".zshrc copied to $HOME."
  else
      warn ".zshrc not found in $DOTFILES_SOURCE, skipping."
  fi

  if [[ -f "$DOTFILES_SOURCE/.p10k.zsh" ]]; then
      cp "$DOTFILES_SOURCE/.p10k.zsh" "$HOME/.p10k.zsh"
      success ".p10k.zsh copied to $HOME."
  else
      warn ".p10k.zsh not found in $DOTFILES_SOURCE, skipping."
  fi

  # Pictures
  if [[ -d "$DOTFILES_SOURCE/Pictures" ]]; then
    cp -r "$DOTFILES_SOURCE/Pictures/." "$HOME/Pictures/"
    success "Pictures copied to $HOME."
  else
    warn "Pictures directory not found in $DOTFILES_SOURCE, skipping."
  fi
}

install_heavy_pkgs() {
  if [[ ${#HEAVY_PKGS[@]} -eq 0 ]]; then
    return
  fi

  echo -e "\n${YELLOW}${BOLD}Pacotes pesados (compilados do source):${RESET}"
  for pkg in "${HEAVY_PKGS[@]}"; do
    echo -e "  ${CYAN}•${RESET} $pkg"
  done

  echo -e "\n${BOLD}Deseja instalar esses pacotes agora? Pode demorar bastante. [y/N]${RESET} "
  read -r response
  if [[ "${response,,}" != "y" ]]; then
    WARNINGS+=("Pacotes pesados não instalados. Rode manualmente: paru -S ${HEAVY_PKGS[*]}")
    warn "Pacotes pesados ignorados."
    return
  fi

  info "Instalando pacotes pesados (Pode demorar um pouco)..."
  for pkg in "${HEAVY_PKGS[@]}"; do
    if ! paru -S --noconfirm --needed "$pkg"; then
      WARNINGS+=("Pacote pesado '$pkg': falha na compilação. Instale manualmente depois.")
      warn "$pkg failed, continuing..."
    else
      success "$pkg installed."
    fi
  done
}

setup_zsh() {
    info "Setting default shell to zsh..."

    local zsh_path
    zsh_path=$(which zsh)

    if [[ "$SHELL" != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
        success "Default shell changed to zsh."
    else
        success "Zsh is already the default shell."
    fi
}

full_install() {
  install_required_packages
  install_system_packages
  install_sddm_if_needed
  install_sddm_theme
  install_extra_packages
  install_heavy_pkgs
  copy_dotfiles
  setup_zsh

  if command -v hyprctl >/dev/null; then
    hyprctl reload
  fi
}

install_dependencies() {
  install_required_packages
  install_system_packages
  install_sddm_if_needed
  install_sddm_theme
  install_extra_packages
  install_heavy_pkgs
}

update_configuration() {
  copy_dotfiles
  setup_zsh
  if command -v hyprctl >/dev/null; then
    hyprctl reload
  fi
}

main() {
  echo
  echo "Dotfiles Installer"
  echo
  echo "1) Instalação Completa"
  echo "2) Instalar dependências"
  echo "3) Atualizar configuração"
  echo "0) Sair"
  echo

  read -rp "Escolha uma opção: " option

  case "$option" in
  1)
    full_install
    ;;
  2)
    install_dependencies
    ;;
  3)
    update_configuration
    ;;
  0)
    exit 0
    ;;
  *)
    die "Opção inválida."
    ;;
  esac

  echo
  success "Concluído."

  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo
    warn "Pendências:"
    for w in "${WARNINGS[@]}"; do
      echo " • $w"
    done
  fi
}

main "$@"
