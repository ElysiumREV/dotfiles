#!/usr/bin/env bash
# =============================================================================
# install.sh — Dotfiles installer for multiple Linux distributions
# =============================================================================

set -e # Abort on error

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Distribution Detection
# -----------------------------------------------------------------------------
detect_distro() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_VERSION=$VERSION_ID
  elif command -v lsb_release &>/dev/null; then
    DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    DISTRO_VERSION=$(lsb_release -sr)
  elif [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
    DISTRO=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
    DISTRO_VERSION=$DISTRIB_RELEASE
  else
    die "Distribuição Linux não suportada ou desconhecida. Não há como continuar."
  fi

  # Normalize distribution names
  case "$DISTRO" in
  arch | archlinux)
    DISTRO="arch"
    ;;
  debian)
    DISTRO="debian"
    ;;
  *)
    die "Unsupported distribution: $DISTRO. Supported: Arch, Debian."
    ;;
  esac

  echo "$DISTRO"
}

# -----------------------------------------------------------------------------
# Package Manager Functions
# -----------------------------------------------------------------------------
install_package() {
  local pkg=$1
  case "$DISTRO" in
  arch)
    if [[ " ${AUR_PKGS[*]} " =~ " ${pkg} " ]]; then
      paru -S --noconfirm --needed "$pkg"
    else
      sudo pacman -S --noconfirm --needed "$pkg"
    fi
    ;;
  debian)
    sudo apt install -y "$pkg"
    ;;
  esac
}

install_packages() {
  local pkgs=("$@")
  case "$DISTRO" in
  arch)
    sudo pacman -S --noconfirm --needed "${pkgs[@]}"
    ;;
  debian)
    sudo apt install -y "${pkgs[@]}"
    ;;
  esac
}

# -----------------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------------
[[ $EUID -eq 0 ]] && die "Não rode o script com sudo ou como root.\nO script cuida dessa parte pedindo sudo quando necessário."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect distribution
DISTRO=$(detect_distro)
info "Distribuição Detectada: $DISTRO"

# Avisos não-fatais acumulados durante a instalação
WARNINGS=()

case "$DISTRO" in
arch)
  PACMAN_PKGS=(
    git
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
    firefox
    mpv
    mpd
    playerctl
    kitty
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman
    ttf-jetbrains-mono-nerd
    pipewire
    pipewire-pulse
    wireplumber
    spotify-launcher
    xdg-desktop-portal-hyprland
    qt5ct
    qt6ct
    kvantum
    kvantum-qt5
    kate
    obsidian
    zed
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
  )

  AUR_PKGS=(
    quickshell
    awww # (swww has been renamed)
    vesktop-bin
    opencode
    vicinae-bin
    hayase-desktop-bin
    stremio-enhanced-bin
  )
  ;;
debian)
  DEBIAN_PKGS=(
    git
    btop
    fastfetch
    brightnessctl
    power-profiles-daemon
    wl-clipboard
    grim
    slurp
    easyeffects
    udiskie
    udisks2
    nemo
    nemo-fileroller
    gnome-keyring
    gvfs
    steam
    firefox
    kitty
    network-manager-applet
    blueman
    fonts-jetbrains-mono
    pipewire
    pipewire-pulse
    wireplumber
    qt5ct
    qt6ct
    kvantum
    kvantum-qt5
    obsidian
    zed
  )
  ;;
esac

# Pacotes que compilam do source — instalação opcional
HEAVY_PKGS=(
  "deepfilternet-demos-git"
  "lsp-plugins"
  "calf"
)

# -----------------------------------------------------------------------------
# Distribution-specific Functions
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
# 1. Install required packages
# -----------------------------------------------------------------------------
install_required_packages() {
  case "$DISTRO" in
  arch)
    install_paru
    ;;
  debian)
    if ! command -v flatpak &>/dev/null; then
      sudo apt-get install -y flatpak
      success "Flatpak installed."
    else
      success "Flatpak already installed."
    fi
    ;;
  esac
}

# -----------------------------------------------------------------------------
# 2. Install system packages
# -----------------------------------------------------------------------------
install_system_packages() {
  case "$DISTRO" in
  arch)
    if [[ ${#PACMAN_PKGS[@]} -eq 0 ]]; then
      warn "No pacman packages defined, skipping."
      return
    fi

    info "Installing pacman packages..."
    sudo pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"
    success "pacman packages installed."
    ;;
  debian)
    if [[ ${#DEBIAN_PKGS[@]} -eq 0 ]]; then
      warn "No Debian packages defined, skipping."
      return
    fi

    info "Installing Debian packages..."
    sudo apt-get update -y
    sudo apt-get install -y "${DEBIAN_PKGS[@]}"
    success "Debian packages installed."
    ;;
  esac
}

# -----------------------------------------------------------------------------
# 3. Install AUR/Flatpak packages
# -----------------------------------------------------------------------------
install_extra_packages() {
  case "$DISTRO" in
  arch)
    if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
      warn "No AUR packages defined, skipping."
      return
    fi

    info "Installing AUR packages..."
    paru -S --noconfirm --needed "${AUR_PKGS[@]}"
    success "AUR packages installed."
    ;;
  esac
}

# -----------------------------------------------------------------------------
# 0. Install SDDM and remove previous DM
# -----------------------------------------------------------------------------
install_sddm_if_needed() {
  local current_dm_service=""
  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    current_dm_service=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)" .service)
  fi

  if [[ -n "$current_dm_service" && "$current_dm_service" != "sddm" ]]; then
    info "Removing previous display manager: $current_dm_service"
    sudo systemctl disable "${current_dm_service}.service" || true
    case "$DISTRO" in
    arch) sudo pacman -Rns --noconfirm "$current_dm_service" || true ;;
    debian) sudo apt-get purge -y "$current_dm_service" || true ;;
    esac
  fi

  info "Installing SDDM..."
  case "$DISTRO" in
  arch) sudo pacman -S --noconfirm --needed sddm ;;
  debian) sudo apt-get install -y sddm ;;
  esac

  sudo systemctl enable sddm
  success "SDDM installed and enabled."
}

# -----------------------------------------------------------------------------
# 4. Copy dotfiles
# -----------------------------------------------------------------------------
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

  # Pictures
  if [[ -d "$DOTFILES_SOURCE/Pictures" ]]; then
    cp -r "$DOTFILES_SOURCE/Pictures/." "$HOME/Pictures/"
    success "Pictures copied to $HOME."
  else
    warn "Pictures directory not found in $DOTFILES_SOURCE, skipping."
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
# 6. Install Kvantum theme (from GitHub, non-fatal)
# -----------------------------------------------------------------------------
install_kvantum_theme() {
  # Check if required Kvantum packages are available
  case "$DISTRO" in
  arch)
    if ! command -v kvantummanager &>/dev/null; then
      warn "Kvantum not found. Installing kvantum package..."
      sudo pacman -S --noconfirm kvantum kvantum-qt5
    fi
    ;;
  debian)
    if ! command -v kvantummanager &>/dev/null; then
      warn "Kvantum not found. Installing kvantum package..."
      sudo apt-get install -y qt5-style-kvantum qt5-style-kvantum-themes
    fi
    ;;
  esac

  # Skip Kvantum theme installation if kvantummanager is not available
  if ! command -v kvantummanager &>/dev/null; then
    warn "Kvantum manager not available, skipping theme installation."
    return
  fi

  info "Installing Colloid KDE theme (Kvantum)..."

  local tmp
  tmp=$(mktemp -d)

  if ! git clone --depth=1 https://github.com/vinceliuice/Colloid-kde.git "$tmp/colloid-kde"; then
    WARNINGS+=("Colloid KDE theme: falha ao clonar o repositório. Instale manualmente depois.")
    warn "Could not clone Colloid KDE theme, skipping."
    rm -rf "$tmp"
    return
  fi

  if ! bash "$tmp/colloid-kde/install.sh"; then
    WARNINGS+=("Colloid KDE theme: install script falhou. Instale manualmente depois.")
    warn "Colloid KDE theme install script failed, skipping."
    rm -rf "$tmp"
    return
  fi

  rm -rf "$tmp"
  success "Colloid KDE theme installed (Kvantum + color schemes)."
}

# -----------------------------------------------------------------------------
# 7. Install Hackneyed cursor theme (from GitLab)
# -----------------------------------------------------------------------------
install_cursor_theme() {
  info "Installing Hackneyed cursor theme..."

  local tmp
  tmp=$(mktemp -d)

  if ! git clone --depth=1 https://gitlab.com/Enthymeme/hackneyed-x11-cursors.git "$tmp/hackneyed-cursors"; then
    WARNINGS+=("Hackneyed cursor theme: falha ao clonar o repositório. Instale manualmente depois.")
    warn "Could not clone Hackneyed cursor theme, skipping."
    rm -rf "$tmp"
    return
  fi

  # Create cursors directory if it doesn't exist
  mkdir -p "$HOME/.icons"

  # Copy the dark theme to the icons directory
  if ! cp -r "$tmp/hackneyed-cursors/hackneyed-dark" "$HOME/.icons/"; then
    WARNINGS+=("Hackneyed cursor theme: falha ao copiar os arquivos. Instale manualmente depois.")
    warn "Could not copy Hackneyed cursor theme files, skipping."
    rm -rf "$tmp"
    return
  fi

  # Set the cursor theme using XDG settings
  if command -v gsettings &>/dev/null; then
    # For GNOME-based environments
    gsettings set org.gnome.desktop.interface cursor-theme 'hackneyed-dark'
  elif command -v xfconf-query &>/dev/null; then
    # For XFCE environments
    xfconf-query -c xsettings -p /Gtk/CursorThemeName -s 'hackneyed-dark'
  fi

  # Create/update ~/.icons/default/index.theme for consistency
  mkdir -p "$HOME/.icons/default"
  cat >"$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=hackneyed-dark
EOF

  # Set cursor theme for Hyprland using hyprcursor
  if command -v hyprctl &>/dev/null; then
    hyprctl setcursor hackneyed-dark 24
    success "Cursor theme set for Hyprland."
  else
    warn "Hyprland not detected, skipping Hyprcursor configuration."
  fi

  rm -rf "$tmp"
  success "Hackneyed cursor theme installed to ~/.icons/hackneyed-dark."
}

# -----------------------------------------------------------------------------
# 7. Install heavy packages (optional, compile from source)
# -----------------------------------------------------------------------------
install_heavy_pkgs() {
  if [[ "$DISTRO" != "arch" ]]; then
    return
  fi
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

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo -e "\n${BOLD}Dotfiles Installer${RESET}\n"

  install_required_packages
  install_system_packages
  install_sddm_if_needed
  install_extra_packages
  install_heavy_pkgs
  copy_dotfiles
  install_colloid_icons
  install_kvantum_theme
  install_cursor_theme

  hyprctl reload

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
