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

    if [[ "$ID" != "arch" && "$ID" != "cachyos" && "${ID_LIKE:-}" != *arch* ]]; then
      die "Este script é para Arch Linux ou distros baseadas nele (ex: CachyOS). Distribuição detectada: $ID."
    fi
  elif [[ ! -f /etc/arch-release ]]; then
    die "Este script é para Arch Linux ou distros baseadas nele (ex: CachyOS). Não foi possível confirmar a distribuição."
  fi
}

[[ $EUID -eq 0 ]] && die "Não rode o script com sudo ou como root.\nO script cuida dessa parte pedindo sudo quando necessário."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_arch
info "Arch Linux/CachyOS confirmado."

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
  pciutils
  unixodbc

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
  hyprshutdown
  mako
  cliphist
  wl-clipboard
  grim
  slurp
  hyprshot

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
  rtkit

  # Network / Bluetooth
  networkmanager
  network-manager-applet
  bluez
  bluez-utils
  blueman

  # Graphics / OpenCL
  ocl-icd
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

# AMD graphics stack.
#
# Instala o stack Mesa/RADV completo para GPUs AMD modernas,
# incluindo componentes 32-bit para Steam/Wine/Proton.

AMD_PKGS=(
  # OpenGL
  mesa
  lib32-mesa

  # Vulkan / RADV
  vulkan-radeon
  lib32-vulkan-radeon

  # VA-API
  libva-mesa-driver
  lib32-libva-mesa-driver

  # VDPAU
  mesa-vdpau
  lib32-mesa-vdpau

  # OpenCL
  opencl-mesa
  lib32-opencl-mesa

  # Firmware
  linux-firmware
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

# ------------------------------------------------------------
# Multilib
# ------------------------------------------------------------

enable_multilib() {
  if grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' /etc/pacman.conf; then
    success "Multilib já está habilitado."
    return
  fi

  info "Habilitando o repositório multilib..."

  if ! grep -Eq '^[[:space:]]*#\[multilib\][[:space:]]*$' /etc/pacman.conf; then
    die "Não foi possível localizar a seção [multilib] em /etc/pacman.conf."
  fi

  sudo sed -i \
    '/^[[:space:]]*#\[multilib\][[:space:]]*$/,/^[[:space:]]*#Include = \/etc\/pacman\.d\/mirrorlist[[:space:]]*$/ {
      s/^[[:space:]]*#\[multilib\]/[multilib]/
      s/^[[:space:]]*#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/
    }' \
    /etc/pacman.conf

  sudo pacman -Sy --noconfirm

  success "Multilib habilitado."
}

# ------------------------------------------------------------
# Package validation
# ------------------------------------------------------------

validate_pacman_packages() {
  local packages=("$@")
  local missing=()

  if [[ ${#packages[@]} -eq 0 ]]; then
    return
  fi

  info "Validando pacotes dos repositórios oficiais..."

  for pkg in "${packages[@]}"; do
    if ! pacman -Si "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo
    warn "Os seguintes pacotes não foram encontrados nos repositórios habilitados:"

    for pkg in "${missing[@]}"; do
      echo -e "  ${RED}•${RESET} $pkg"
    done

    echo

    die "Existem pacotes inválidos ou indisponíveis. Corrija a lista de pacotes antes de continuar."
  fi

  success "Todos os pacotes foram encontrados."
}

# ------------------------------------------------------------
# paru
# ------------------------------------------------------------

install_paru() {
  if command -v paru &>/dev/null; then
    success "paru already installed, skipping."
    return
  fi

  info "Installing dependencies required to build paru..."

  sudo pacman -Syu --noconfirm --needed git base-devel

  info "Installing paru..."

  local tmp
  tmp=$(mktemp -d)

  git clone https://aur.archlinux.org/paru.git "$tmp/paru"

  (
    cd "$tmp/paru"
    makepkg -si --noconfirm
  )

  rm -rf "$tmp"

  success "paru installed."
}

install_required_packages() {
  install_paru
}

# ------------------------------------------------------------
# GPU detection
# ------------------------------------------------------------

GPU_VENDOR="unknown"

detect_gpu() {
  info "Detectando GPU..."

  local gpu_info

  if ! command -v lspci &>/dev/null; then
    warn "lspci não está disponível. Não foi possível detectar a GPU."
    return
  fi

  gpu_info=$(lspci | grep -Ei 'VGA compatible controller|3D controller|Display controller' || true)

  if [[ -z "$gpu_info" ]]; then
    warn "Nenhuma GPU PCI foi detectada."
    return
  fi

  echo
  echo -e "${BOLD}GPUs detectadas:${RESET}"
  echo "$gpu_info"
  echo

  # AMD tem prioridade para notebooks híbridos.
  # Exemplo:
  # Intel UHD + AMD Radeon
  #
  # Nesse caso queremos instalar o stack AMD também.

  if echo "$gpu_info" | grep -qiE 'AMD|ATI'; then
    GPU_VENDOR="amd"
  elif echo "$gpu_info" | grep -qi 'NVIDIA'; then
    GPU_VENDOR="nvidia"
  elif echo "$gpu_info" | grep -qi 'Intel'; then
    GPU_VENDOR="intel"
  else
    GPU_VENDOR="unknown"
  fi

  case "$GPU_VENDOR" in
  amd)
    success "GPU AMD detectada."
    ;;

  nvidia)
    success "GPU NVIDIA detectada."
    ;;

  intel)
    success "GPU Intel detectada."
    ;;

  *)
    warn "Fabricante da GPU não identificado."
    ;;
  esac
}

install_gpu_drivers() {
  detect_gpu

  case "$GPU_VENDOR" in
  amd)
    info "Instalando stack gráfico AMD..."

    validate_pacman_packages "${AMD_PKGS[@]}"

    sudo pacman -S --noconfirm --needed "${AMD_PKGS[@]}"

    success "Stack gráfico AMD instalado."
    ;;

  intel)
    info "GPU Intel detectada."
    warn "Drivers AMD não serão instalados."
    ;;

  nvidia)
    info "GPU NVIDIA detectada."
    warn "Drivers AMD não serão instalados."
    ;;

  *)
    warn "Não foi possível determinar a GPU."
    warn "Nenhum driver específico será instalado."
    ;;
  esac
}

# ------------------------------------------------------------
# System packages
# ------------------------------------------------------------

install_system_packages() {
  if [[ ${#PACMAN_PKGS[@]} -eq 0 ]]; then
    warn "No pacman packages defined, skipping."
    return
  fi

  validate_pacman_packages "${PACMAN_PKGS[@]}"

  info "Installing pacman packages..."

  sudo pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"

  success "pacman packages installed."
}

# ------------------------------------------------------------
# AUR
# ------------------------------------------------------------

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
    WARNINGS+=(
      "Pacotes AUR não instalados. Rode manualmente: paru -S ${AUR_PKGS[*]}"
    )

    warn "Pacotes AUR ignorados."
    return
  fi

  info "Installing AUR packages..."

  if ! paru -S --needed "${AUR_PKGS[@]}"; then
    WARNINGS+=(
      "Falha ao instalar um ou mais pacotes AUR. Rode manualmente: paru -S ${AUR_PKGS[*]}"
    )

    warn "Falha na instalação de pacotes AUR."
    return
  fi

  success "AUR packages installed."
}

# ------------------------------------------------------------
# SDDM
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Dotfiles
# ------------------------------------------------------------

copy_dotfiles() {
  info "Copying dotfiles..."

  # Source directory for dotfiles
  local DOTFILES_SOURCE="$DOTFILES_DIR/configurations/home/ely"

  # .config
  if [[ -d "$DOTFILES_SOURCE/.config" ]]; then
    mkdir -p "$HOME/.config"

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
    mkdir -p "$HOME/Pictures"

    cp -r "$DOTFILES_SOURCE/Pictures/." "$HOME/Pictures/"

    success "Pictures copied to $HOME."
  else
    warn "Pictures directory not found in $DOTFILES_SOURCE, skipping."
  fi
}

# ------------------------------------------------------------
# Heavy packages
# ------------------------------------------------------------

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
    WARNINGS+=(
      "Pacotes pesados não instalados. Rode manualmente: paru -S ${HEAVY_PKGS[*]}"
    )

    warn "Pacotes pesados ignorados."
    return
  fi

  info "Instalando pacotes pesados (Pode demorar um pouco)..."

  for pkg in "${HEAVY_PKGS[@]}"; do
    if ! paru -S --needed "$pkg"; then
      WARNINGS+=(
        "Pacote pesado '$pkg': falha na compilação. Instale manualmente depois."
      )

      warn "$pkg failed, continuing..."
    else
      success "$pkg installed."
    fi
  done
}

# ------------------------------------------------------------
# Zsh
# ------------------------------------------------------------

setup_zsh() {
  info "Setting default shell to zsh..."

  local zsh_path
  zsh_path=$(command -v zsh)

  if [[ -z "$zsh_path" ]]; then
    warn "zsh não foi encontrado. Não foi possível alterar o shell."
    return
  fi

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    sudo chsh -s "$zsh_path" "$USER"
    success "Default shell changed to zsh."
  else
    success "Zsh is already the default shell."
  fi
}

# ------------------------------------------------------------
# Installation flows
# ------------------------------------------------------------

full_install() {
  install_required_packages
  enable_multilib

  install_system_packages
  install_gpu_drivers

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
  enable_multilib

  install_system_packages
  install_gpu_drivers

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

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

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
