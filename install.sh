#!/usr/bin/env bash

set -e

# ============================================================
# Dotfiles Installer
#
# Supported:
#   - Arch Linux
#   - CachyOS (and other Arch-based distros)
#
# Uses:
#   - pacman
#   - paru/AUR
#   - multilib
# ============================================================

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

info() {
  echo -e "${CYAN}${BOLD}==> ${RESET}${BOLD}$*${RESET}"
}

success() {
  echo -e "${GREEN}${BOLD}  ✓ ${RESET}$*"
}

warn() {
  echo -e "${YELLOW}${BOLD}  ! ${RESET}$*"
}

die() {
  echo -e "${RED}${BOLD}  ✗ ERROR: ${RESET}$*"
  exit 1
}

# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------

[[ $EUID -eq 0 ]] && die \
  "Não rode o script com sudo ou como root.
O script cuida dessa parte pedindo sudo quando necessário."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WARNINGS=()

GPU_VENDOR="unknown"

# ------------------------------------------------------------
# Distribution check
# ------------------------------------------------------------

check_distro() {
  if [[ ! -f /etc/os-release ]]; then
    die "Não foi possível identificar a distribuição."
  fi

  . /etc/os-release

  case "$ID" in
  arch | cachyos)
    ;;

  *)
    if [[ "${ID_LIKE:-}" != *arch* ]]; then
      die "Distribuição não suportada: ${PRETTY_NAME:-$ID}"
    fi
    ;;
  esac

  echo
  success "Arch-based detectado: ${PRETTY_NAME:-$ID}"
  echo
}

# ============================================================
# ARCH PACKAGES
# ============================================================

PACMAN_PKGS=(
  # Base / Utilities
  git
  base-devel
  fish
  fisher
  starship
  vim
  neovim
  pciutils
  unixodbc
  eza
  plasma-workspace

  android-tools
  gvfs-mtp

  xdg-user-dirs
  awww

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
  cliphist
  wl-clipboard
  hyprshot
  matugen

  # File manager
  nautilus
  ffmpegthumbnailer

  # Audio
  easyeffects
  noise-suppression-for-voice
  pipewire
  pipewire-pulse
  pipewire-alsa
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
  lib32-libva
  lib32-libjpeg-turbo
  lib32-ocl-icd
  lib32-gtk3

  # Desktop applications
  firefox
  mpv
  vlc # fallback
  imv
  featherpad
  kitty
  spotify-launcher
  kate
  obsidian
  zed
  bitwarden
  discord
  telegram-desktop
  qbittorrent
  partitionmanager
  gimp

  # GTK / Qt / Theming
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xdg-desktop-portal-kde
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
  #otf-space-grotesk
  #ttf-readex-pro
  #ttf-rubik-vf
  #ttf-twemoji

  # Remote desktop / streaming
  moonlight-qt
)

# ------------------------------------------------------------
# AMD graphics stack
# ------------------------------------------------------------

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

  # OpenCL
  opencl-mesa
  lib32-opencl-mesa
)

# ------------------------------------------------------------
# AUR
# ------------------------------------------------------------

AUR_PKGS=(
  opencode-beta
  breeze-plus
  darkly-bin
  kde-material-you-colors
  hayase-desktop-bin
  stremio-enhanced-bin
  sunshine-bin
  davinci-resolve
)

# ------------------------------------------------------------
# Heavy packages
# ------------------------------------------------------------

HEAVY_PKGS=(
  "noise-suppression-for-voice"
  "ladspa"
)

# ============================================================
# MULTILIB
# ============================================================

enable_multilib() {
  if grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' /etc/pacman.conf; then
    success "Multilib já está habilitado."
    return 0
  fi

  info "Habilitando o repositório multilib..."

  if ! grep -Eq '^[[:space:]]*#\[multilib\][[:space:]]*$' /etc/pacman.conf; then
    die "A seção [multilib] não foi encontrada em /etc/pacman.conf."
  fi

  sudo sed -i \
    -e '/^[[:space:]]*#\[multilib\][[:space:]]*$/s/^#//' \
    -e '/^[[:space:]]*#Include[[:space:]]*=[[:space:]]*\/etc\/pacman\.d\/mirrorlist[[:space:]]*$/s/^#//' \
    /etc/pacman.conf

  success "Multilib habilitado."
}

# ============================================================
# PACMAN
# ============================================================

validate_pacman_packages() {
  local packages=("$@")

  [[ ${#packages[@]} -eq 0 ]] && return 0

  info "Atualizando bases do Pacman..."

  sudo pacman -Sy --noconfirm

  local missing=()

  for pkg in "${packages[@]}"; do
    if ! pacman -Si "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo
    warn "Pacotes não encontrados nos repositórios habilitados:"

    for pkg in "${missing[@]}"; do
      echo -e "  ${RED}•${RESET} $pkg"
    done

    echo
    die "Existem pacotes Arch indisponíveis."
  fi

  success "Todos os pacotes Arch foram encontrados."
}

install_paru() {
  if command -v paru &>/dev/null; then
    success "paru já está instalado."
    return
  fi

  info "Instalando dependências necessárias para compilar paru..."

  sudo pacman -Syu --noconfirm --needed git base-devel

  info "Instalando paru..."

  local tmp
  tmp=$(mktemp -d)

  git clone https://aur.archlinux.org/paru.git "$tmp/paru"

  (
    cd "$tmp/paru"
    makepkg -si --noconfirm
  )

  rm -rf "$tmp"

  success "paru instalado."
}

install_arch_system_packages() {
  validate_pacman_packages "${PACMAN_PKGS[@]}"

  info "Instalando pacotes Arch..."

  sudo pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"

  success "Pacotes Arch instalados."
}

# ============================================================
# AUR
# ============================================================

install_extra_packages() {
  if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
    return
  fi

  echo
  echo -e "${YELLOW}${BOLD}Pacotes AUR:${RESET}"

  for pkg in "${AUR_PKGS[@]}"; do
    echo -e "  ${CYAN}•${RESET} $pkg"
  done

  echo
  echo -e "${BOLD}Deseja instalar os pacotes AUR agora? [y/N]${RESET}"
  read -r response

  if [[ "${response,,}" != "y" ]]; then
    WARNINGS+=(
      "Pacotes AUR não instalados. Rode manualmente: paru -S ${AUR_PKGS[*]}"
    )

    warn "Pacotes AUR ignorados."
    return
  fi

  info "Instalando pacotes AUR..."

  if ! paru -S --needed "${AUR_PKGS[@]}"; then
    WARNINGS+=(
      "Falha ao instalar um ou mais pacotes AUR. Rode manualmente: paru -S ${AUR_PKGS[*]}"
    )

    warn "Falha na instalação de pacotes AUR."
    return
  fi

  success "Pacotes AUR instalados."
}

# ============================================================
# GPU DETECTION
# ============================================================

detect_gpu() {
  info "Detectando GPU..."

  local gpu_info

  if ! command -v lspci &>/dev/null; then
    warn "lspci não está disponível. Não foi possível detectar a GPU."
    return
  fi

  gpu_info=$(
    lspci |
      grep -Ei \
        'VGA compatible controller|3D controller|Display controller' ||
      true
  )

  if [[ -z "$gpu_info" ]]; then
    warn "Nenhuma GPU PCI foi detectada."
    return
  fi

  echo
  echo -e "${BOLD}GPUs detectadas:${RESET}"
  echo "$gpu_info"
  echo

  # AMD tem prioridade em notebooks híbridos.
  #
  # Exemplo:
  # Intel UHD + AMD Radeon
  #
  # Nesse caso instalamos o stack AMD também.

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

# ============================================================
# GPU DRIVERS
# ============================================================

install_gpu_drivers() {
  detect_gpu

  case "$GPU_VENDOR" in

  amd)
    info "Instalando stack gráfico AMD..."

    sudo pacman -Syu \
      --noconfirm \
      --needed \
      "${AMD_PKGS[@]}"

    success "Stack gráfico AMD instalado."
    ;;

  intel)
    info "Instalando stack gráfico Intel/Mesa..."

    sudo pacman -Syu \
      --noconfirm \
      --needed \
      mesa \
      vulkan-intel \
      lib32-mesa \
      lib32-vulkan-intel

    success "Stack gráfico Intel instalado."
    ;;

  nvidia)
    info "GPU NVIDIA detectada."

    warn "Drivers NVIDIA não serão instalados automaticamente."
    warn "Configure o driver NVIDIA conforme sua necessidade."
    ;;

  *)
    warn "Não foi possível determinar a GPU."
    warn "Nenhum driver específico será instalado."
    ;;
  esac
}

# ============================================================
# Ly (Display Manager)
# ============================================================

install_ly_if_needed() {
  local current_dm_service=""

  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    current_dm_service=$(
      basename \
        "$(readlink -f /etc/systemd/system/display-manager.service)" \
        .service
    )
  fi

  # Se houver um DM diferente do Ly, desabilita ele
  if [[ -n "$current_dm_service" && "$current_dm_service" != "ly" ]]; then
    info "Display manager atual detectado: $current_dm_service"
    warn "Desabilitando o display manager atual ($current_dm_service)..."
    sudo systemctl disable "${current_dm_service}.service" || true
  fi

  info "Instalando Ly..."
  # Ly geralmente está no AUR (ly-git) ou repositórios específicos.
  if ! paru -S --noconfirm --needed ly; then
    die "Falha ao instalar o Ly. Verifique a conexão ou o repositório."
  fi

  info "Habilitando Ly..."
  sudo systemctl enable ly@tty1.service

  success "Troca de Display Manager concluída com sucesso, pode desinstalar o outro."
}

# ============================================================
# DOTFILES
# ============================================================

copy_dotfiles() {
  info "Copiando dotfiles..."

  local DOTFILES_SOURCE="$DOTFILES_DIR/configurations/home/ely"

  # ----------------------------------------------------------
  # .config
  # ----------------------------------------------------------

  if [[ -d "$DOTFILES_SOURCE/.config" ]]; then

    mkdir -p "$HOME/.config"

    cp -r \
      "$DOTFILES_SOURCE/.config/." \
      "$HOME/.config/"

    success ".config copiado para $HOME."

  else
    warn ".config não encontrado em:"
    warn "$DOTFILES_SOURCE"
  fi

  # ----------------------------------------------------------
  # Pictures
  # ----------------------------------------------------------

  if [[ -d "$DOTFILES_SOURCE/Pictures" ]]; then

    mkdir -p "$HOME/Pictures"

    cp -r \
      "$DOTFILES_SOURCE/Pictures/." \
      "$HOME/Pictures/"

    success "Pictures copiado."

  else
    warn "Pictures não encontrado."
  fi
}

# ============================================================
# HEAVY PACKAGES
# ============================================================

install_heavy_pkgs() {
  if [[ ${#HEAVY_PKGS[@]} -eq 0 ]]; then
    return
  fi

  echo
  echo -e "${YELLOW}${BOLD}Pacotes pesados:${RESET}"

  for pkg in "${HEAVY_PKGS[@]}"; do
    echo -e "  ${CYAN}•${RESET} $pkg"
  done

  echo
  echo -e \
    "${BOLD}Deseja instalar esses pacotes agora?
Pode demorar bastante. [y/N]${RESET}"

  read -r response

  if [[ "${response,,}" != "y" ]]; then

    WARNINGS+=(
      "Pacotes pesados não instalados. Rode: paru -S ${HEAVY_PKGS[*]}"
    )

    warn "Pacotes pesados ignorados."
    return
  fi

  info "Instalando pacotes pesados..."

  for pkg in "${HEAVY_PKGS[@]}"; do

    if ! paru -S --needed "$pkg"; then

      WARNINGS+=(
        "Pacote pesado '$pkg' falhou na compilação."
      )

      warn "$pkg falhou, continuando..."

    else
      success "$pkg instalado."
    fi
  done
}

# ============================================================
# FISH
# ============================================================

setup_fish() {
  info "Configurando Fish como shell padrão..."

  local fish_path current_shell user_name

  user_name="$(id -un)"
  fish_path="$(command -v fish || true)"

  if [[ -z "$fish_path" || ! -x "$fish_path" ]]; then
    warn "Fish não foi encontrado ou não é executável."
    return 1
  fi

  # Garante que o Fish esteja listado como shell válido.
  if ! grep -Fxq "$fish_path" /etc/shells; then
    info "Adicionando Fish a /etc/shells..."
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  # Consulta o shell registrado no banco de usuários.
  current_shell="$(getent passwd "$user_name" | cut -d: -f7)"

  if [[ "$current_shell" != "$fish_path" ]]; then
    info "Alterando shell padrão para Fish..."

    if ! sudo usermod --shell "$fish_path" "$user_name"; then
      die "Não foi possível definir o Fish como shell padrão."
    fi

    success "Fish definido como shell padrão."
  else
    success "Fish já é o shell padrão."
  fi

  # Sincroniza os plugins do Fisher, se houver configuração.
  if [[ -f "$HOME/.config/fish/fish_plugins" ]]; then
    info "Sincronizando plugins do Fisher..."
    fish -c "fisher update"
    success "Plugins do Fisher sincronizados."
  fi
  }fi
}

# ============================================================
# Installation flow
# ============================================================

install_dependencies() {
  info "Iniciando instalação para Arch/CachyOS..."

  install_paru

  enable_multilib

  install_arch_system_packages

  install_gpu_drivers

  install_ly_if_needed

  install_extra_packages

  install_heavy_pkgs
}

# ============================================================
# Configuration
# ============================================================

update_configuration() {
  copy_dotfiles

  setup_fish

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload 2>/dev/null || true
  fi
}

# ============================================================
# Full installation
# ============================================================

full_install() {
  install_dependencies

  update_configuration
}

# ============================================================
# Main
# ============================================================

main() {

  check_distro

  echo
  echo -e "${BOLD}Dotfiles Installer${RESET}"
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

  # ----------------------------------------------------------
  # Warnings
  # ----------------------------------------------------------

  if [[ ${#WARNINGS[@]} -gt 0 ]]; then

    echo
    warn "Pendências:"

    for w in "${WARNINGS[@]}"; do
      echo " • $w"
    done
  fi
}

main "$@"
