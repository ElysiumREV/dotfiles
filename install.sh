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
PACMAN_DB_SYNCED=0

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
  # Base para usar os dotfiles
  git
  base-devel
  flatpak
  fish
  starship
  neovim
  kitty
  firefox
  dolphin
  xdg-user-dirs
  gvfs
  gnome-keyring
  curl
  pciutils

  # Utilitários para o uso diário
  fastfetch
  btop

  # Sessão Hyprland e componentes usados pela configuração
  hyprland
  quickshell
  hypridle
  hyprlock
  hyprsunset
  hyprpicker
  hyprpolkitagent
  hyprshutdown
  awww
  matugen
  udiskie
  brightnessctl
  grim
  imagemagick
  wl-clipboard
  playerctl
  bluez
  bluez-utils
  networkmanager
  upower

  # Áudio e integração Wayland
  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber
  rtkit
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk

  # Fontes básicas para a interface
  ttf-jetbrains-mono-nerd
  ttf-material-symbols-variable
  noto-fonts
  noto-fonts-emoji
)

# Aplicativos e recursos extras; ficam fora da instalação padrão.
OPTIONAL_SYSTEM_PKGS=(
  vim eza unixodbc android-tools gvfs-mtp wpa_supplicant ufw
  cups cups-pk-helper system-config-printer power-profiles-daemon udisks2
  cliphist hyprshot network-manager-applet blueman
  ark ffmpegthumbs kdegraphics-thumbnailers kio-admin kde-cli-tools purpose
  kimageformats qt6-imageformats unrar zip unzip 7zip ffmpegthumbnailer
)

OPTIONAL_MEDIA_PKGS=(
  easyeffects noise-suppression-for-voice gst-plugin-pipewire gst-plugins-base-libs
  pavucontrol mpd mpv vlc imv
)

OPTIONAL_STEAM_PKGS=(
  steam lib32-alsa-plugins lib32-libva lib32-libjpeg-turbo lib32-gtk3
)

OPTIONAL_GAMING_TOOLS_PKGS=(
  gamescope mangohud lib32-mangohud umu-launcher protontricks winetricks lutris goverlay
)

OPTIONAL_GAMING_LIBS_PKGS=(
  ocl-icd vulkan-tools glfw openal libva giflib mpg123 alsa-plugins lib32-ocl-icd
)

OPTIONAL_STREAMING_PKGS=(
  moonlight-qt
)

OPTIONAL_APPS_PKGS=(
  featherpad kate obsidian zed qbittorrent
)

OPTIONAL_COMMUNICATION_PKGS=(
  bitwarden discord telegram-desktop
)

OPTIONAL_CREATIVE_PKGS=(
  gimp partitionmanager spotify-launcher
)

OPTIONAL_THEMING_PKGS=(
  xdg-desktop-portal-kde qt5ct qt6ct kvantum kvantum-qt5 adw-gtk-theme nwg-look
  papirus-icon-theme noto-fonts-cjk noto-fonts-extra ttf-liberation
)

OPTIONAL_SELECTED_PKGS=()

# ------------------------------------------------------------
# AMD graphics stack
# ------------------------------------------------------------

AMD_PKGS=(
  mesa
  vulkan-radeon
  libva-mesa-driver
)

# ------------------------------------------------------------
# AUR
# ------------------------------------------------------------

AUR_PKGS=(
  opencode-beta
  breeze-plus
  darkly-bin
  kde-material-you-colors
  spicetify-cli
)

# ------------------------------------------------------------
# Heavy packages
# ------------------------------------------------------------

HEAVY_PKGS=(
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
  if [[ "$PACMAN_DB_SYNCED" != "1" ]]; then
    die "As bases do Pacman ainda não foram sincronizadas com atualização completa."
  fi

  validate_pacman_packages "${PACMAN_PKGS[@]}"

  info "Instalando pacotes Arch..."

  sudo pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}"

  success "Pacotes Arch instalados."
}

install_optional_group() {
  local group_name="$1"
  local group_variable="$2"
  local -n group_packages="$group_variable"
  local response

  echo
  echo -e "${YELLOW}${BOLD}${group_name}:${RESET}"
  printf '  %s\n' "${group_packages[@]}"
  read -rp "Instalar este grupo? [y/N] " response

  if [[ "${response,,}" == "y" ]]; then
    OPTIONAL_SELECTED_PKGS+=("${group_packages[@]}")
  else
    WARNINGS+=("Grupo opcional ignorado: ${group_name}.")
  fi
}

install_optional_arch_packages() {
  install_optional_group "Ferramentas e integração" OPTIONAL_SYSTEM_PKGS
  install_optional_group "Áudio e mídia" OPTIONAL_MEDIA_PKGS
  install_optional_group "Steam e bibliotecas 32-bit" OPTIONAL_STEAM_PKGS
  install_optional_group "Ferramentas de jogos" OPTIONAL_GAMING_TOOLS_PKGS
  install_optional_group "Bibliotecas e ferramentas gráficas" OPTIONAL_GAMING_LIBS_PKGS
  install_optional_group "Streaming remoto" OPTIONAL_STREAMING_PKGS
  install_optional_group "Aplicativos" OPTIONAL_APPS_PKGS
  install_optional_group "Comunicação" OPTIONAL_COMMUNICATION_PKGS
  install_optional_group "Criação e utilitários gráficos" OPTIONAL_CREATIVE_PKGS
  install_optional_group "Temas e personalização" OPTIONAL_THEMING_PKGS

  if [[ ${#OPTIONAL_SELECTED_PKGS[@]} -eq 0 ]]; then
    return
  fi

  validate_pacman_packages "${OPTIONAL_SELECTED_PKGS[@]}"
  sudo pacman -S --noconfirm --needed "${OPTIONAL_SELECTED_PKGS[@]}"
  success "Grupos opcionais instalados."
}

sync_system_once() {
  info "Atualizando o sistema e sincronizando os repositórios uma vez..."
  sudo pacman -Syu --noconfirm
  PACMAN_DB_SYNCED=1
}

configure_flatpak() {
  info "Configurando Flathub para o usuário atual..."
  flatpak remote-add --if-not-exists --user flathub \
    https://flathub.org/repo/flathub.flatpakrepo
  success "Flatpak pronto para instalar aplicativos do Flathub."
}

ensure_system_service() {
  local unit="$1"

  if systemctl is-enabled --quiet "$unit" && systemctl is-active --quiet "$unit"; then
    success "$unit já está habilitado e ativo."
    return 0
  fi

  info "Ativando serviço essencial: $unit..."
  if sudo systemctl enable --now "$unit"; then
    success "$unit habilitado e ativo."
  else
    WARNINGS+=("Não foi possível habilitar/iniciar $unit.")
    warn "Não foi possível habilitar/iniciar $unit; confira manualmente."
  fi
}

ensure_user_service() {
  local unit="$1"

  if systemctl --user is-enabled --quiet "$unit" && systemctl --user is-active --quiet "$unit"; then
    success "Serviço de usuário $unit já está habilitado e ativo."
    return 0
  fi

  info "Ativando serviço de áudio do usuário: $unit..."
  if systemctl --user enable --now "$unit"; then
    success "$unit habilitado e ativo para o usuário."
  else
    WARNINGS+=("Não foi possível habilitar/iniciar o serviço de usuário $unit.")
    warn "Não foi possível habilitar/iniciar $unit; confira manualmente."
  fi
}

ensure_essential_services() {
  ensure_system_service NetworkManager.service
  ensure_system_service bluetooth.service
  ensure_system_service upower.service

  ensure_user_service pipewire.socket
  ensure_user_service pipewire-pulse.socket
  ensure_user_service wireplumber.service
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

  install_paru
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

  # AMD tem prioridade quando o sistema também possui uma GPU NVIDIA.

  if echo "$gpu_info" | grep -qiE 'AMD|ATI'; then
    GPU_VENDOR="amd"

  elif echo "$gpu_info" | grep -qi 'NVIDIA'; then
    GPU_VENDOR="nvidia"

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

  *)
    warn "Fabricante da GPU não identificado."
    ;;
  esac
}

# ============================================================
# GPU DRIVERS
# ============================================================

install_gpu_drivers() {
  case "$GPU_VENDOR" in

  amd)
    info "Instalando stack gráfico AMD..."

    sudo pacman -S \
      --noconfirm \
      --needed \
      "${AMD_PKGS[@]}"

    success "Stack gráfico AMD instalado."
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
    warn "Desabilitando o display manager atual ($current_dm_service) para os próximos boots..."
    # Não use --now nem pare o serviço: o usuário pode estar nessa sessão.
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

backup_dotfile_conflicts() {
  local source_root="$1"
  local target_root="$2"
  local source_file relative destination backup_root="" backup_base
  local conflict_count=0

  [[ -d "$source_root" ]] || return 0

  while IFS= read -r -d '' source_file; do
    relative="${source_file#"$source_root"/}"
    destination="$target_root/$relative"

    if [[ -e "$destination" || -L "$destination" ]]; then
      if [[ -z "$backup_root" ]]; then
        backup_base="$HOME/.local/share/dotfiles-backups"
        mkdir -p "$backup_base"
        backup_root="$(mktemp -d "$backup_base/backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
        info "Arquivos existentes que serão substituídos em $target_root:"
      fi

      echo "  $relative"
      mkdir -p "$backup_root/$(dirname "$relative")"
      cp -a "$destination" "$backup_root/$relative"
      conflict_count=$((conflict_count + 1))
    fi
  done < <(find "$source_root" \( -type f -o -type l \) -print0)

  if (( conflict_count > 0 )); then
    success "$conflict_count arquivo(s) salvo(s) em $backup_root antes da cópia."
  fi
}

copy_dotfiles() {
  info "Copiando dotfiles..."

  local DOTFILES_SOURCE="$DOTFILES_DIR/configurations/home/ely"

  # ----------------------------------------------------------
  # .config
  # ----------------------------------------------------------

  if [[ -d "$DOTFILES_SOURCE/.config" ]]; then

    mkdir -p "$HOME/.config"
    backup_dotfile_conflicts "$DOTFILES_SOURCE/.config" "$HOME/.config"

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
    backup_dotfile_conflicts "$DOTFILES_SOURCE/Pictures" "$HOME/Pictures"

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

  install_paru
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
    if ! fish -c 'type -q fisher'; then
      info "Instalando Fisher..."
      local fisher_script
      fisher_script="$(mktemp)"
      if ! curl --fail --location --silent --show-error \
        --output "$fisher_script" \
        https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish; then
        rm -f "$fisher_script"
        die "Não foi possível baixar o instalador do Fisher."
      fi

      if ! fish -c "source '$fisher_script'; fisher install jorgebucaran/fisher"; then
        rm -f "$fisher_script"
        die "Não foi possível instalar o Fisher."
      fi
      rm -f "$fisher_script"
    fi

    info "Sincronizando plugins do Fisher..."
    fish -c "fisher update"
    success "Plugins do Fisher sincronizados."
  fi
}

# ============================================================
# Installation flow
# ============================================================

install_dependencies() {
  info "Iniciando instalação para Arch/CachyOS..."

  enable_multilib
  sync_system_once
  install_arch_system_packages

  install_paru
  detect_gpu
  case "$GPU_VENDOR" in
    amd)
      OPTIONAL_STEAM_PKGS+=(lib32-mesa lib32-vulkan-radeon)
      ;;
    nvidia)
      OPTIONAL_STEAM_PKGS+=(lib32-nvidia-utils)
      ;;
  esac

  install_optional_arch_packages

  configure_flatpak
  ensure_essential_services

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
