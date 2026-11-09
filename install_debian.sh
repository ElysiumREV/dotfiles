#!/usr/bin/env bash

set -e

# ============================================================
# Dotfiles Installer — Debian 13 (trixie)
#
# Divisão:
#   - apt:  base do sistema, áudio, rede, display manager, portais
#   - Nix:  Hyprland, Quickshell e ferramentas de usuário (via
#           home-manager, flake em nix/), com Mesa do Nix envolvido
#           pelo nixGL
#
# Os nomes dos pacotes apt abaixo devem ser conferidos com
# `apt-cache policy <pacote>` antes da primeira execução.
# ============================================================

# ------------------------------------------------------------
# Cores
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
# Verificações básicas
# ------------------------------------------------------------

[[ $EUID -eq 0 ]] && die \
  "Não rode o script com sudo ou como root.
O script cuida dessa parte pedindo sudo quando necessário."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WARNINGS=()

# ------------------------------------------------------------
# Verificação da distribuição
# ------------------------------------------------------------

check_distro() {
  if [[ ! -f /etc/os-release ]]; then
    die "Não foi possível identificar a distribuição."
  fi

  . /etc/os-release

  if [[ "$ID" != "debian" ]]; then
    die "Este script é para Debian. Detectado: ${PRETTY_NAME:-$ID}"
  fi

  if [[ "${VERSION_ID:-}" != "13" ]]; then
    warn "Testado no Debian 13 (trixie); detectado: ${PRETTY_NAME:-$ID}"
    WARNINGS+=("Versão do Debian diferente de 13: os nomes de pacotes podem não existir.")
  fi

  echo
  success "Debian detectado: ${PRETTY_NAME:-$ID}"
  echo
}

# ============================================================
# APT
#
# Só o que o Nix não cuida: integração com systemd, dbus, PAM,
# hardware e serviços do sistema. Hyprland e Quickshell NÃO
# entram aqui (vêm do Nix).
# ============================================================

PKGS_APT_BASE=(
  git
  curl
  xz-utils
  ca-certificates
  sudo
  fish
  kitty
  pciutils
  flatpak
  xdg-user-dirs
  gvfs
  gnome-keyring
)

PKGS_APT_SYSTEM=(
  network-manager
  bluez
  blueman
  upower
  power-profiles-daemon
  udisks2
  cups
  sddm
)

PKGS_APT_AUDIO=(
  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber
  rtkit
  pavucontrol
)

# Portais e Wayland para Qt/GTK. O portal do Hyprland vem do Nix
# junto com o compositor, então aqui ficam só os outros.
PKGS_APT_THEME=(
  xdg-desktop-portal-gtk
  xdg-desktop-portal-kde
  qtwayland5
  qt6-wayland
  qt6ct
  qt-style-kvantum
  papirus-icon-theme
  dconf-cli
)

PKGS_APT_FILES=(
  dolphin
  ark
  ffmpegthumbs
  kio-admin
)

PKGS_APT_SESSION_HELPERS=(
  brightnessctl
  grim
  wl-clipboard
  playerctl
  libnotify-bin
  udiskie
)

PKGS_APT_AMD=(
  mesa-vulkan-drivers
  libgl1-mesa-dri
)

# AMD/Mesa do sistema: o Mesa do Nix é o que o nixGL usa, mas o
# kernel e o Vulkan do sistema continuam vindo do apt.
GPU_VENDOR="unknown"

# ------------------------------------------------------------
# APT: instalação
# ------------------------------------------------------------

install_apt_packages() {
  info "Atualizando índice do apt..."
  sudo apt-get update

  local all_pkgs=(
    "${PKGS_APT_BASE[@]}"
    "${PKGS_APT_SYSTEM[@]}"
    "${PKGS_APT_AUDIO[@]}"
    "${PKGS_APT_THEME[@]}"
    "${PKGS_APT_FILES[@]}"
    "${PKGS_APT_SESSION_HELPERS[@]}"
  )

  info "Instalando pacotes apt..."
  sudo apt-get install -y "${all_pkgs[@]}"

  success "Pacotes apt instalados."
}

install_apt_gpu() {
  case "$GPU_VENDOR" in
  amd)
    info "Instalando componentes Mesa/Vulkan do sistema para AMD..."
    sudo apt-get install -y "${PKGS_APT_AMD[@]}"
    success "Componentes AMD instalados."
    ;;
  nvidia)
    warn "GPU NVIDIA: instale o driver manualmente (pacote nvidia-driver do Debian ou o oficial)."
    WARNINGS+=("GPU NVIDIA: o driver não é instalado automaticamente.")
    ;;
  *)
    warn "Não foi possível determinar a GPU; nenhum driver específico será instalado."
    ;;
  esac
}

detect_gpu() {
  info "Detectando GPU..."

  if ! command -v lspci &>/dev/null; then
    warn "lspci não está disponível; a GPU não foi detectada."
    return
  fi

  local gpu_info
  gpu_info=$(
    lspci |
      grep -Ei 'VGA compatible controller|3D controller|Display controller' ||
      true
  )

  if echo "$gpu_info" | grep -qiE 'AMD|ATI'; then
    GPU_VENDOR="amd"
    success "GPU AMD detectada."
  elif echo "$gpu_info" | grep -qi 'NVIDIA'; then
    GPU_VENDOR="nvidia"
    success "GPU NVIDIA detectada."
  else
    warn "Fabricante da GPU não identificado."
  fi
}

# ------------------------------------------------------------
# SERVIÇOS
# ------------------------------------------------------------

ensure_system_service() {
  local unit="$1"

  if systemctl is-enabled --quiet "$unit" 2>/dev/null && systemctl is-active --quiet "$unit"; then
    success "$unit já está habilitado e ativo."
    return 0
  fi

  info "Ativando serviço: $unit..."
  if sudo systemctl enable --now "$unit"; then
    success "$unit habilitado e ativo."
  else
    WARNINGS+=("Não foi possível habilitar/iniciar $unit.")
    warn "Não foi possível habilitar/iniciar $unit; confira manualmente."
  fi
}

ensure_user_service() {
  local unit="$1"

  if systemctl --user is-enabled --quiet "$unit" 2>/dev/null && systemctl --user is-active --quiet "$unit"; then
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
  ensure_system_service cups.socket

  ensure_user_service pipewire.socket
  ensure_user_service pipewire-pulse.socket
  ensure_user_service wireplumber.service
}

# O SDDM do Debian vira o display manager. Se outro DM estiver
# ativo, ele é desabilitado só depois que o SDDM estiver instalado.
setup_display_manager() {
  local current_dm_service=""

  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    current_dm_service=$(
      basename \
        "$(readlink -f /etc/systemd/system/display-manager.service)" \
        .service
    )
  fi

  if [[ -n "$current_dm_service" && "$current_dm_service" != "sddm" ]]; then
    info "Display manager atual detectado: $current_dm_service"
    warn "Desabilitando $current_dm_service para os próximos boots..."
    # Sem --now: o usuário pode estar nessa sessão.
    sudo systemctl disable "${current_dm_service}.service" || true
  fi

  sudo systemctl enable sddm.service
  success "SDDM configurado como display manager."
}

# ------------------------------------------------------------
# NIX
# ------------------------------------------------------------

load_nix_env() {
  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
}

install_nix() {
  load_nix_env

  if command -v nix &>/dev/null; then
    success "Nix já está instalado."
    return
  fi

  info "Instalando Nix (instalador multiusuário com flakes habilitado)..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm

  load_nix_env

  if ! command -v nix &>/dev/null; then
    die "Nix não foi encontrado após a instalação. Abra um novo terminal e rode o script de novo."
  fi

  success "Nix instalado."
}

# Sem isso o Nix ignora o cache do cachix do Hyprland ("not a trusted user").
allow_trusted_user() {
  local user_name
  user_name="$(id -un)"

  if nix config show 2>/dev/null | grep -qE "^trusted-users = .*\b${user_name}\b"; then
    success "Usuário $user_name já é trusted-user do Nix."
    return
  fi

  info "Adicionando $user_name aos trusted-users do Nix (cache do Hyprland)..."
  echo "trusted-users = root $user_name" | sudo tee -a /etc/nix/nix.custom.conf >/dev/null
  sudo systemctl restart nix-daemon.service
  success "trusted-users atualizado."
}

# Aplica o flake nix/ com home-manager. Na primeira vez usa
# `nix run` para buscar o home-manager; depois ele fica disponível.
apply_home_manager() {
  info "Aplicando nix/ com home-manager (Hyprland, Quickshell, Mesa do Nix)..."

  # Aceita as configurações de cache do flake (cachix do Hyprland).
  export NIX_CONFIG="accept-flake-config = true"

  local flake="$DOTFILES_DIR/nix#ely"

  if command -v home-manager &>/dev/null; then
    home-manager switch --flake "$flake" -b backup
  else
    nix run home-manager/master -- switch --flake "$flake" -b backup
  fi

  success "Ambiente do Nix aplicado."
}

# Sessão do Hyprland para o display manager. Aponta para o
# start-hyprland do perfil do Nix (já envolvido pelo nixGL).
install_hyprland_session() {
  local session_file="/usr/share/wayland-sessions/hyprland-nix.desktop"
  local start_bin="$HOME/.nix-profile/bin/start-hyprland"

  if [[ ! -x "$start_bin" ]]; then
    WARNINGS+=("start-hyprland não encontrado em $start_bin; a sessão do Hyprland não foi criada.")
    warn "start-hyprland não encontrado; sessão não criada."
    return
  fi

  info "Criando sessão do Hyprland para o display manager..."

  sudo tee "$session_file" >/dev/null <<EOF
[Desktop Entry]
Name=Hyprland (Nix)
Comment=Hyprland instalado pelo Nix
Exec=$start_bin
Type=Application
DesktopNames=Hyprland
EOF

  success "Sessão criada em $session_file."
  WARNINGS+=("Sessão Hyprland (Nix): confira no SDDM se o compositor sobe com o Mesa do Nix. Se não subir, teste nixGL manualmente.")
}

# ------------------------------------------------------------
# DOTFILES
# ------------------------------------------------------------

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

  if ((conflict_count > 0)); then
    success "$conflict_count arquivo(s) salvo(s) em $backup_root antes da cópia."
  fi
}

# Substitui /home/ely pelo $HOME real nos arquivos copiados.
fix_hardcoded_paths() {
  local source_config="$1"
  local file relative

  [[ "$HOME" == "/home/ely" ]] && return 0

  info "Ajustando caminhos /home/ely para $HOME..."

  while IFS= read -r -d '' file; do
    relative="${file#"$source_config"/}"
    sed -i "s|/home/ely|$HOME|g" "$HOME/.config/$relative"
  done < <(grep -rlIZ '/home/ely' "$source_config" || true)

  success "Caminhos ajustados."
}

copy_dotfiles() {
  info "Copiando dotfiles..."

  local DOTFILES_SOURCE="$DOTFILES_DIR/configurations/home/ely"

  if [[ -d "$DOTFILES_SOURCE/.config" ]]; then
    mkdir -p "$HOME/.config"
    backup_dotfile_conflicts "$DOTFILES_SOURCE/.config" "$HOME/.config"

    cp -r "$DOTFILES_SOURCE/.config/." "$HOME/.config/"
    fix_hardcoded_paths "$DOTFILES_SOURCE/.config"

    success ".config copiado para $HOME."
  else
    warn ".config não encontrado em: $DOTFILES_SOURCE"
  fi

  if [[ -d "$DOTFILES_SOURCE/Pictures" ]]; then
    mkdir -p "$HOME/Pictures"
    backup_dotfile_conflicts "$DOTFILES_SOURCE/Pictures" "$HOME/Pictures"

    cp -r "$DOTFILES_SOURCE/Pictures/." "$HOME/Pictures/"

    success "Pictures copiado."
  else
    warn "Pictures não encontrado."
  fi
}

# Cria o .current-wallpaper.png esperado pelo updateWall.sh e roda o
# matugen uma vez (matugen e imagemagick vêm do Nix).
seed_wallpaper() {
  local wall_dir="$HOME/Pictures/Wallpapers"
  local current="$wall_dir/.current-wallpaper.png"
  local seed="$wall_dir/wallhaven-pomle9.jpg"

  if [[ -f "$current" ]]; then
    success "Wallpaper atual já existe."
    return 0
  fi

  if [[ ! -f "$seed" ]]; then
    warn "Wallpaper inicial não encontrado: $seed"
    return 0
  fi

  if ! command -v magick &>/dev/null; then
    warn "magick não encontrado; não foi possível gerar o wallpaper inicial."
    return 0
  fi

  info "Gerando wallpaper inicial e cores do matugen..."
  magick "$seed" "$current"

  if command -v matugen &>/dev/null; then
    if matugen image "$current" --mode dark --source-color-index 0; then
      success "Cores geradas pelo matugen."
    else
      WARNINGS+=("matugen terminou com erro; algum post_hook pode ter falhado.")
    fi
  fi
}

# ------------------------------------------------------------
# FISH
# ------------------------------------------------------------

setup_fish() {
  info "Configurando Fish como shell padrão..."

  local fish_path current_shell user_name

  user_name="$(id -un)"
  fish_path="$(command -v fish || true)"

  if [[ -z "$fish_path" || ! -x "$fish_path" ]]; then
    warn "Fish não foi encontrado ou não é executável."
    return 1
  fi

  if ! grep -Fxq "$fish_path" /etc/shells; then
    info "Adicionando Fish a /etc/shells..."
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

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
}

# ------------------------------------------------------------
# Fluxo de instalação
# ------------------------------------------------------------

install_dependencies() {
  info "Iniciando instalação para Debian..."

  install_apt_packages
  detect_gpu
  install_apt_gpu

  install_nix
  allow_trusted_user
  apply_home_manager
  install_hyprland_session

  ensure_essential_services
  setup_display_manager
}

update_configuration() {
  load_nix_env
  copy_dotfiles
  seed_wallpaper

  setup_fish

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload 2>/dev/null || true
  fi
}

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
  echo -e "${BOLD}Dotfiles Installer (Debian)${RESET}"
  echo
  echo "1) Instalação Completa"
  echo "2) Instalar dependências"
  echo "3) Atualizar configuração"
  echo "0) Sair"
  echo

  read -rp "Escolha uma opção: " option

  case "$option" in
  1) full_install ;;
  2) install_dependencies ;;
  3) update_configuration ;;
  0) exit 0 ;;
  *) die "Opção inválida." ;;
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
