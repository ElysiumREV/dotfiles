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

install_package() {
  local pkg=$1
  if [[ " ${AUR_PKGS[*]} " =~ " ${pkg} " ]]; then
    paru -S --noconfirm --needed "$pkg"
  else
    sudo pacman -S --noconfirm --needed "$pkg"
  fi
}

install_packages() {
  local pkgs=("$@")
  sudo pacman -S --noconfirm --needed "${pkgs[@]}"
}

[[ $EUID -eq 0 ]] && die "Não rode o script com sudo ou como root.\nO script cuida dessa parte pedindo sudo quando necessário."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_arch
info "Arch Linux confirmado."

WARNINGS=()

PACMAN_PKGS=(
  git
  hyprland
  hyprsunset
  hypridle
  hyprlock
  hyprpicker
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
  ffmpegthumbnailer
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

# -----------------------------------------------------------------------------
# 2. Install system packages
# -----------------------------------------------------------------------------
install_system_packages() {
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
    sudo pacman -Rns --noconfirm "$current_dm_service" || true
  fi

  info "Installing SDDM..."
  sudo pacman -S --noconfirm --needed sddm

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
  if ! command -v kvantummanager &>/dev/null; then
    warn "Kvantum not found. Installing kvantum package..."
    sudo pacman -S --noconfirm kvantum kvantum-qt5
  fi

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
