#!/usr/bin/env bash

set -e

# ============================================================
# Dotfiles Installer
#
# Supported:
#   - Arch Linux
#   - CachyOS
#   - Fedora
#
# Fedora:
#   - Uses DNF
#   - Enables RPM Fusion
#   - Enables lionheartp/Hyprland COPR
#   - Uses .i686 packages for 32-bit gaming libraries
#
# Arch:
#   - Uses pacman
#   - Uses paru/AUR
#   - Enables multilib
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

DISTRO="unknown"
GPU_VENDOR="unknown"


# ------------------------------------------------------------
# Distribution detection
# ------------------------------------------------------------

detect_distro() {
  if [[ ! -f /etc/os-release ]]; then
    die "Não foi possível identificar a distribuição."
  fi

  . /etc/os-release

  case "$ID" in
    arch|cachyos)
      DISTRO="arch"
      ;;

    fedora)
      DISTRO="fedora"
      ;;

    *)
      if [[ "${ID_LIKE:-}" == *arch* ]]; then
        DISTRO="arch"
      elif [[ "${ID_LIKE:-}" == *fedora* ]]; then
        DISTRO="fedora"
      else
        die "Distribuição não suportada: ${PRETTY_NAME:-$ID}"
      fi
      ;;
  esac

  echo

  case "$DISTRO" in
    arch)
      success "Arch-based detectado: ${PRETTY_NAME:-$ID}"
      ;;

    fedora)
      success "Fedora detectado: ${PRETTY_NAME:-Fedora}"
      ;;
  esac

  echo
}


# ============================================================
# ARCH PACKAGES
# ============================================================

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
  eza

  android-tools
  gvfs-mtp

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

  # Remote desktop / streaming
  moonlight-qt

  # AI / dev tools
  opencode
)


# ------------------------------------------------------------
# Arch AMD graphics stack
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
  awww
  zsh-theme-powerlevel10k-git
  vicinae-bin
  hayase-desktop-bin
  stremio-enhanced-bin
  sunshine-bin
)


# ------------------------------------------------------------
# Arch heavy packages
# ------------------------------------------------------------

HEAVY_PKGS=(
  "deepfilternet-demos-git"
  "lsp-plugins"
  "calf"
)


# ============================================================
# FEDORA PACKAGES
# ============================================================

FEDORA_COPR="lionheartp/Hyprland"


# ------------------------------------------------------------
# Fedora main packages
# ------------------------------------------------------------

FEDORA_PKGS=(
  # Base / Utilities
  git
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  vim
  neovim
  pciutils
  unixODBC
  eza

  android-tools
  gvfs-mtp

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

  # Desktop
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
  hyprshot

  # File manager
  nemo
  nemo-fileroller
  ffmpegthumbnailer

  # Audio
  easyeffects
  pipewire
  pipewire-pulseaudio
  pipewire-alsa
  wireplumber
  pavucontrol
  playerctl
  mpd
  rtkit

  # GStreamer / PipeWire
  gstreamer1-plugins-base
  gstreamer1-plugin-pipewire

  # Network / Bluetooth
  NetworkManager
  network-manager-applet
  bluez
  bluez-tools
  blueman

  # Graphics / OpenCL
  ocl-icd
  mesa-libOpenCL
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
  openal-soft
  libva
  giflib
  mpg123
  alsa-plugins

  # Desktop applications
  firefox
  mpv
  kitty
  kate
  qbittorrent

  # GTK / Qt / Theming
  xdg-desktop-portal-hyprland
  qt5-qtbase
  qt6-qtbase
  kvantum
  kvantum-qt5
  nwg-look
  papirus-icon-theme

  # Fonts
  jetbrains-mono-fonts
  google-noto-fonts
  google-noto-emoji-fonts
  liberation-fonts

  # Remote desktop / streaming
  moonlight-qt

  # Misc
  steam-devices
)


# ------------------------------------------------------------
# Fedora 32-bit packages
#
# Fedora uses .i686 instead of Arch's lib32-* naming.
# ------------------------------------------------------------

FEDORA_32BIT_PKGS=(
  mesa-dri-drivers.i686
  mesa-vulkan-drivers.i686
  libva.i686
  alsa-plugins-pulseaudio.i686
  ocl-icd.i686
  gtk3.i686
  mangohud.i686
)


# ------------------------------------------------------------
# Fedora AMD graphics stack
# ------------------------------------------------------------

FEDORA_AMD_PKGS=(
  # OpenGL
  mesa-dri-drivers
  mesa-libGL
  mesa-libEGL

  # Vulkan / RADV
  mesa-vulkan-drivers

  # VA-API
  libva-mesa-driver

  # OpenCL
  mesa-libOpenCL
  ocl-icd

  # 32-bit
  mesa-dri-drivers.i686
  mesa-vulkan-drivers.i686
  libva-mesa-driver.i686
  mesa-libOpenCL.i686
  ocl-icd.i686
)


# ------------------------------------------------------------
# Fedora Intel graphics stack
# ------------------------------------------------------------

FEDORA_INTEL_PKGS=(
  mesa-dri-drivers
  mesa-vulkan-drivers
  mesa-va-drivers
  mesa-libGL
  mesa-libEGL

  mesa-dri-drivers.i686
  mesa-vulkan-drivers.i686
)


# ------------------------------------------------------------
# Fedora optional / Flatpak applications
#
# These are not required for the base desktop to work.
# ------------------------------------------------------------

FEDORA_OPTIONAL_DNF_PKGS=(
  obsidian
  zed
  bitwarden
  discord
  spotify-client
  opencode
)


FEDORA_OPTIONAL_FLATPAKS=(
  com.obsproject.Studio
)


# ============================================================
# MULTILIB - ARCH
# ============================================================

enable_multilib() {
  [[ "$DISTRO" != "arch" ]] && return 0

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
  [[ "$DISTRO" != "arch" ]] && return 0

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

install_extra_packages_arch() {
  [[ "$DISTRO" != "arch" ]] && return 0

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
# FEDORA REPOSITORIES
# ============================================================

enable_fedora_copr() {
  [[ "$DISTRO" != "fedora" ]] && return 0

  info "Configurando COPR: $FEDORA_COPR..."

  # dnf-plugins-core fornece o comando copr.
  if ! rpm -q dnf5-plugins &>/dev/null; then
    sudo dnf install -y dnf5-plugins
  fi

  if sudo dnf copr list 2>/dev/null | grep -qi \
      'lionheartp/Hyprland'; then

    success "COPR $FEDORA_COPR já está habilitado."
    return
  fi

  sudo dnf copr enable -y "$FEDORA_COPR"

  success "COPR $FEDORA_COPR habilitado."
}


enable_rpmfusion() {
  [[ "$DISTRO" != "fedora" ]] && return 0

  info "Verificando RPM Fusion..."

  if ! rpm -q rpmfusion-free-release &>/dev/null; then
    info "Habilitando RPM Fusion Free..."

    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
  else
    success "RPM Fusion Free já está habilitado."
  fi

  if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
    info "Habilitando RPM Fusion Nonfree..."

    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
  else
    success "RPM Fusion Nonfree já está habilitado."
  fi

  success "RPM Fusion configurado."
}


# ============================================================
# DNF
# ============================================================

dnf_package_available() {
  local pkg="$1"

  # Already installed
  if rpm -q "$pkg" &>/dev/null; then
    return 0
  fi

  # Available from enabled repositories
  dnf repoquery --available "$pkg" &>/dev/null
}


install_available_dnf_packages() {
  local packages=("$@")
  local available=()
  local missing=()

  [[ ${#packages[@]} -eq 0 ]] && return 0

  for pkg in "${packages[@]}"; do
    if dnf_package_available "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo
    warn "Pacotes Fedora não encontrados e que serão ignorados:"

    for pkg in "${missing[@]}"; do
      echo -e "  ${YELLOW}•${RESET} $pkg"
    done

    echo
  fi

  if [[ ${#available[@]} -eq 0 ]]; then
    warn "Nenhum pacote disponível nesta lista."
    return 0
  fi

  sudo dnf install -y "${available[@]}"
}


install_fedora_system_packages() {
  info "Atualizando metadados do Fedora..."

  sudo dnf upgrade --refresh -y

  info "Instalando pacotes Fedora..."

  install_available_dnf_packages "${FEDORA_PKGS[@]}"

  success "Pacotes Fedora principais processados."
}


install_fedora_32bit() {
  info "Instalando bibliotecas 32-bit para Steam/Wine/Proton..."

  install_available_dnf_packages "${FEDORA_32BIT_PKGS[@]}"

  success "Bibliotecas 32-bit processadas."
}


install_fedora_optional_packages() {
  echo
  echo -e "${YELLOW}${BOLD}Pacotes opcionais Fedora:${RESET}"

  for pkg in "${FEDORA_OPTIONAL_DNF_PKGS[@]}"; do
    echo -e "  ${CYAN}•${RESET} $pkg"
  done

  echo
  echo -e "${BOLD}Deseja tentar instalar os pacotes opcionais disponíveis? [y/N]${RESET}"
  read -r response

  if [[ "${response,,}" != "y" ]]; then
    WARNINGS+=(
      "Pacotes opcionais Fedora não instalados."
    )

    warn "Pacotes opcionais ignorados."
    return
  fi

  info "Instalando pacotes opcionais disponíveis..."

  install_available_dnf_packages "${FEDORA_OPTIONAL_DNF_PKGS[@]}"

  success "Pacotes opcionais processados."
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

      if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Syu \
          --noconfirm \
          --needed \
          "${AMD_PKGS[@]}"

      elif [[ "$DISTRO" == "fedora" ]]; then
        install_available_dnf_packages \
          "${FEDORA_AMD_PKGS[@]}"
      fi

      success "Stack gráfico AMD instalado."
      ;;


    intel)
      info "Instalando stack gráfico Intel/Mesa..."

      if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Syu \
          --noconfirm \
          --needed \
          mesa \
          vulkan-intel \
          lib32-mesa \
          lib32-vulkan-intel

      elif [[ "$DISTRO" == "fedora" ]]; then
        install_available_dnf_packages \
          "${FEDORA_INTEL_PKGS[@]}"
      fi

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
# SDDM
# ============================================================

install_sddm_if_needed() {
  local current_dm_service=""

  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    current_dm_service=$(
      basename \
        "$(readlink -f /etc/systemd/system/display-manager.service)" \
        .service
    )
  fi

  if [[ -n "$current_dm_service" &&
        "$current_dm_service" != "sddm" ]]; then

    info "Display manager atual: $current_dm_service"

    warn "O script vai desabilitar o display manager atual."

    sudo systemctl disable \
      "${current_dm_service}.service" || true

    # Só remove automaticamente em Arch.
    #
    # No Fedora é melhor não remover o DM anterior
    # automaticamente para evitar quebrar a instalação.

    if [[ "$DISTRO" == "arch" ]]; then
      sudo pacman -Rns \
        --noconfirm \
        "$current_dm_service" || true
    fi
  fi

  info "Instalando SDDM..."

  if [[ "$DISTRO" == "arch" ]]; then
    sudo pacman -S \
      --noconfirm \
      --needed \
      sddm

  elif [[ "$DISTRO" == "fedora" ]]; then
    sudo dnf install \
      -y \
      sddm
  fi

  sudo systemctl enable sddm

  success "SDDM instalado e habilitado."
}


# ============================================================
# SilentSDDM
# ============================================================

install_sddm_theme() {
  local theme_dir="/usr/share/sddm/themes/silent"
  local sddm_conf="/etc/sddm.conf"

  if [[ -d "$theme_dir" ]] &&
     grep -Pzq \
       '\[Theme\]\nCurrent=silent' \
       "$sddm_conf" 2>/dev/null; then

    success "Tema SilentSDDM já está aplicado, pulando."
    return
  fi

  info "Instalando SilentSDDM..."

  local tmp
  tmp=$(mktemp -d)

  if ! git clone \
      https://github.com/uiriansan/SilentSDDM.git \
      "$tmp/SilentSDDM"; then

    rm -rf "$tmp"

    WARNINGS+=(
      "Não foi possível clonar o SilentSDDM."
    )

    warn "Falha ao baixar SilentSDDM."
    return
  fi

  if [[ -f "$tmp/SilentSDDM/install.sh" ]]; then

    chmod +x "$tmp/SilentSDM/install.sh" 2>/dev/null || true

    # Corrige caso o diretório esperado exista.
    chmod +x "$tmp/SilentSDDM/install.sh"

    (
      cd "$tmp/SilentSDDM"
      ./install.sh
    ) || {
      WARNINGS+=(
        "SilentSDDM falhou durante a instalação."
      )

      warn "SilentSDDM falhou durante a instalação."
    }

    success "SilentSDDM processado."

  else
    warn "SilentSDDM install.sh não encontrado."

    WARNINGS+=(
      "SilentSDDM install.sh não encontrado."
    )
  fi

  rm -rf "$tmp"
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
  # .zshrc
  # ----------------------------------------------------------

  if [[ -f "$DOTFILES_SOURCE/.zshrc" ]]; then

    cp \
      "$DOTFILES_SOURCE/.zshrc" \
      "$HOME/.zshrc"

    success ".zshrc copiado."

  else
    warn ".zshrc não encontrado."
  fi


  # ----------------------------------------------------------
  # .p10k.zsh
  # ----------------------------------------------------------

  if [[ -f "$DOTFILES_SOURCE/.p10k.zsh" ]]; then

    cp \
      "$DOTFILES_SOURCE/.p10k.zsh" \
      "$HOME/.p10k.zsh"

    success ".p10k.zsh copiado."

  else
    warn ".p10k.zsh não encontrado."
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
# HEAVY PACKAGES - ARCH ONLY
# ============================================================

install_heavy_pkgs() {
  [[ "$DISTRO" != "arch" ]] && return 0

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
# ZSH
# ============================================================

setup_zsh() {
  info "Configurando Zsh como shell padrão..."

  local zsh_path

  zsh_path=$(command -v zsh || true)

  if [[ -z "$zsh_path" ]]; then
    warn "zsh não foi encontrado."
    return
  fi

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then

    sudo chsh \
      -s "$zsh_path" \
      "$(id -un)"

    success "Zsh definido como shell padrão."

  else
    success "Zsh já é o shell padrão."
  fi
}


# ============================================================
# Fedora optional Flatpak
# ============================================================

install_fedora_flatpak() {
  [[ "$DISTRO" != "fedora" ]] && return 0

  if ! command -v flatpak &>/dev/null; then
    return 0
  fi

  if [[ ${#FEDORA_OPTIONAL_FLATPAKS[@]} -eq 0 ]]; then
    return 0
  fi

  echo
  echo -e "${YELLOW}${BOLD}Flatpaks opcionais:${RESET}"

  for app in "${FEDORA_OPTIONAL_FLATPAKS[@]}"; do
    echo -e "  ${CYAN}•${RESET} $app"
  done

  echo
  echo -e \
    "${BOLD}Deseja instalar esses Flatpaks? [y/N]${RESET}"

  read -r response

  if [[ "${response,,}" != "y" ]]; then
    warn "Flatpaks opcionais ignorados."
    return
  fi

  for app in "${FEDORA_OPTIONAL_FLATPAKS[@]}"; do

    if flatpak info "$app" &>/dev/null; then
      success "$app já está instalado."
      continue
    fi

    if ! flatpak install -y flathub "$app"; then
      WARNINGS+=(
        "Flatpak '$app' não pôde ser instalado."
      )

      warn "Falha ao instalar $app."
    else
      success "$app instalado."
    fi
  done
}


# ============================================================
# Installation flows
# ============================================================

install_arch_dependencies() {
  info "Iniciando instalação para Arch/CachyOS..."

  install_paru

  enable_multilib

  install_arch_system_packages

  install_gpu_drivers

  install_sddm_if_needed

  install_sddm_theme

  install_extra_packages_arch

  install_heavy_pkgs
}


install_fedora_dependencies() {
  info "Iniciando instalação para Fedora..."

  enable_rpmfusion

  enable_fedora_copr

  info "Atualizando metadados dos repositórios..."

  sudo dnf makecache

  install_fedora_system_packages

  install_fedora_32bit

  install_gpu_drivers

  install_sddm_if_needed

  install_sddm_theme

  install_fedora_optional_packages

  install_fedora_flatpak
}


install_dependencies() {
  case "$DISTRO" in

    arch)
      install_arch_dependencies
      ;;

    fedora)
      install_fedora_dependencies
      ;;

    *)
      die "Distribuição não suportada."
      ;;
  esac
}


# ============================================================
# Configuration
# ============================================================

update_configuration() {
  copy_dotfiles

  setup_zsh

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

  detect_distro

  echo
  echo -e "${BOLD}Dotfiles Installer${RESET}"
  echo
  echo "Distribuição: $DISTRO"
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