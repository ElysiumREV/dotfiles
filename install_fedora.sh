#!/usr/bin/env bash

set -e

# ============================================================
# Dotfiles Installer — Fedora
#
# Suportado:
#   - Fedora 43+ (Minimal / Everything / Workstation)
#
# Diferenças em relação ao install.sh (Arch/CachyOS):
#   - dnf + COPR + RPM Fusion no lugar de pacman + AUR + multilib
#   - Terra (Fyra Labs) habilitado por padrão: lazygit, awww e o que mais ele
#     tiver é instalado de lá antes de recorrer a COPRs/binários
#   - Hyprland vem de COPR (com checagem de versão mínima)
#   - awww: COPR -> compila do código-fonte -> swaybg (fallback)
#   - Pacotes ausentes NÃO abortam o script: viram "Pendências"
#   - Sobe o sistema para graphical.target e instala um display manager
#
# Variáveis de ambiente (opcionais):
#   HYPRLAND_COPR=dono/projeto    força um COPR específico para o Hyprland
#   HYPRLAND_MIN_VERSION=0.55.0   versão mínima aceita (0 desativa a checagem)
#   DISPLAY_MANAGER=ly|sddm|none  padrão: ly (cai para sddm se não existir)
#   AWWW_GIT_REF=v0.x.y           tag do awww usada no build (padrão: última)
#   HYPR_EXTRAS_COPR=dono/projeto COPR só para hyprsunset/hyprpicker/etc.
#                                 (padrão: nett00n/hyprland e noclog/...; vazio desativa)
#   ENABLE_TERRA=0                não habilita o repositório Terra
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

GPU_VENDOR="unknown"
DNF_SYNCED=0
HYPRLAND_COPR_USED=""

# Resultado de classify_packages
FOUND_PKGS=()
MISSING_PKGS=()

# O Hyprland 0.55 introduziu a config em Lua. Se suas configs ainda forem
# .conf, rode com HYPRLAND_MIN_VERSION=0.
HYPRLAND_MIN_VERSION="${HYPRLAND_MIN_VERSION:-0.55.0}"

# Ordem de tentativa (o primeiro que tiver build recente o bastante vence).
HYPRLAND_COPRS=(
  solopasha/hyprland
  ashbuk/Hyprland-Fedora
  noclog/hyprlandthingswithautoupdater
)

ENABLE_TERRA="${ENABLE_TERRA:-1}"

DISPLAY_MANAGER="${DISPLAY_MANAGER:-ly}"

# COPR usado apenas para os utilitários hypr* que faltarem (hyprsunset,
# hyprpicker, hyprpolkitagent, hyprshutdown, hyprshot).
# HYPR_EXTRAS_COPR (mesmo vazio) substitui a lista padrão; vazio = desativa.
if [[ -v HYPR_EXTRAS_COPR ]]; then
  HYPR_EXTRAS_COPRS=()
  if [[ -n "$HYPR_EXTRAS_COPR" ]]; then
    HYPR_EXTRAS_COPRS=("$HYPR_EXTRAS_COPR")
  fi
else
  HYPR_EXTRAS_COPRS=(nett00n/hyprland noclog/hyprlandthingswithautoupdater)
fi

AWWW_GIT_URL="https://codeberg.org/LGFae/awww.git"
AWWW_GIT_REF="${AWWW_GIT_REF:-}"

# ------------------------------------------------------------
# Verificação da distribuição
# ------------------------------------------------------------

check_distro() {
  if [[ ! -f /etc/os-release ]]; then
    die "Não foi possível identificar a distribuição."
  fi

  . /etc/os-release

  if [[ "$ID" != "fedora" && "${ID_LIKE:-}" != *fedora* ]]; then
    die "Distribuição não suportada: ${PRETTY_NAME:-$ID}"
  fi

  command -v dnf &>/dev/null || die "dnf não encontrado."

  if [[ "${VERSION_ID:-}" =~ ^[0-9]+$ ]] && ((VERSION_ID < 43)); then
    WARNINGS+=("Fedora ${VERSION_ID}: o script foi pensado para 43+; COPRs podem não ter build para esta versão.")
  fi

  echo
  success "Fedora detectado: ${PRETTY_NAME:-$ID}"
  echo
}

# ============================================================
# PACOTES (dnf)
#
# Os nomes são validados em tempo de execução. Pacote que não
# existir NÃO aborta a instalação: vira item em "Pendências".
# Nomes de pacotes "x.i686" são as libs 32-bit (Steam/Proton).
# ============================================================

PKGS_BASE=(
  git
  curl
  tar
  xz
  jq
  slurp
  pciutils
  flatpak
  xdg-user-dirs
  xdg-utils
  gvfs
  gvfs-mtp
  gnome-keyring
  fish
  neovim
  vim-enhanced
  kitty
  fastfetch
  btop
  eza
  zip
  unzip
  unrar
  7zip
  python3
  python3-pip
  python3-devel
  pipx
  gcc
  gcc-c++
  make
  cmake
  pkgconf-pkg-config
  dbus-devel
  glib2-devel
  fontconfig
  polkit
)

# Componentes chamados pelas configs (hypr*, quickshell, matugen e awww
# têm tratamento próprio: veja install_hyprland, install_shell_stack
# e install_awww).
PKGS_SESSION=(
  udiskie
  brightnessctl
  grim
  ImageMagick
  wl-clipboard
  playerctl
  libnotify
)

# Serviços de sistema que o Quickshell consulta
PKGS_SYSTEM=(
  NetworkManager
  NetworkManager-wifi
  wpa_supplicant
  network-manager-applet
  bluez
  blueman
  upower
  power-profiles-daemon
  udisks2
  cups
  cups-pk-helper
  system-config-printer
  android-tools
  unixODBC
)

# Áudio. O librnnoise_ladspa.so exigido por
# pipewire.conf.d/99-input-denoising.conf vem de COPR: veja
# install_noise_suppression.
PKGS_AUDIO=(
  pipewire
  pipewire-pulseaudio
  pipewire-alsa
  pipewire-gstreamer
  wireplumber
  rtkit
  gstreamer1-plugins-base
  pavucontrol
)

# Portais, Wayland para Qt e tema. O hyprland-portals.conf usa
# hyprland + gtk (padrão) e kde (FileChooser), então os três
# portais precisam estar instalados (o do Hyprland vem em install_hyprland).
PKGS_THEME=(
  xdg-desktop-portal
  xdg-desktop-portal-gtk
  xdg-desktop-portal-kde
  qt5-qtwayland
  qt6-qtwayland
  qt5ct
  qt6ct
  kvantum
  kvantum-qt5
  adw-gtk3-theme
  papirus-icon-theme
  dconf
  gsettings-desktop-schemas
)

# JetBrainsMono Nerd Font e Material Symbols não têm pacote oficial:
# veja install_fonts_extra.
PKGS_FONTS=(
  google-noto-sans-fonts
  google-noto-serif-fonts
  google-noto-sans-mono-fonts
  google-noto-color-emoji-fonts
  google-noto-sans-cjk-fonts
  liberation-fonts
)

# Dolphin e integração (thumbnails, arquivos compactados, etc.)
PKGS_FILES=(
  dolphin
  dolphin-plugins
  ark
  ffmpegthumbs
  ffmpegthumbnailer
  kdegraphics-thumbnailers
  kio-admin
  kde-cli-tools
  kf6-purpose
  kf6-kimageformats
  qt6-qtimageformats
)

# Ferramentas de desenvolvimento esperadas pelo Neovim (LazyVim, Telescope,
# Treesitter e Mason). git, curl, unzip e gcc já vêm de PKGS_BASE.
# lazygit não tem pacote no Fedora: veja install_lazygit.
PKGS_DEV=(
  ripgrep
  fd-find
  tree-sitter-cli
  nodejs
  npm
)

FEDORA_PKGS=(
  "${PKGS_BASE[@]}"
  "${PKGS_SESSION[@]}"
  "${PKGS_SYSTEM[@]}"
  "${PKGS_AUDIO[@]}"
  "${PKGS_THEME[@]}"
  "${PKGS_FONTS[@]}"
  "${PKGS_FILES[@]}"
  "${PKGS_DEV[@]}"
)

# Aplicativos do dia a dia (discord, telegram, vlc vêm do RPM Fusion).
FEDORA_APPS=(
  firefox
  kate
  zed
  qbittorrent
  bitwarden
  kde-partitionmanager
  discord
  telegram-desktop
  mpd
  mpv
  vlc
  imv
)

# Se o app não existir nos repositórios, tenta o Flathub.
declare -A FLATPAK_FALLBACKS=(
  [zed]="dev.zed.Zed"
  [bitwarden]="com.bitwarden.desktop"
  [discord]="com.discordapp.Discord"
)

# Grupo opcional (pergunta antes de instalar)
OPTIONAL_GAMING_PKGS=(
  steam
  gamescope
  mangohud
  umu-launcher
  protontricks
  winetricks
  lutris
  goverlay
  vulkan-tools
  ocl-icd
  openal-soft
  libva
  giflib
  mpg123
)

OPTIONAL_SELECTED_PKGS=()

# ------------------------------------------------------------
# Stack gráfico por fabricante
# ------------------------------------------------------------

AMD_PKGS=(
  mesa-dri-drivers
  mesa-vulkan-drivers
  mesa-va-drivers
  libva-utils
)

INTEL_PKGS=(
  mesa-dri-drivers
  mesa-vulkan-drivers
)

# ============================================================
# DNF: helpers
# ============================================================

# Retorna 0 se o pacote existir (por nome ou por "provides").
pkg_available() {
  local spec="${1%.i686}"

  dnf repoquery --quiet --available "$spec" 2>/dev/null | grep -q . ||
    dnf repoquery --quiet --available --whatprovides "$spec" 2>/dev/null | grep -q .
}

# Separa os pacotes recebidos em FOUND_PKGS e MISSING_PKGS.
classify_packages() {
  FOUND_PKGS=()
  MISSING_PKGS=()

  [[ $# -eq 0 ]] && return 0

  local pkg base names

  # Uma consulta em lote; só os que não aparecem são checados um a um.
  names="$(dnf repoquery --quiet --available --qf '%{name}\n' "${@%.i686}" 2>/dev/null | sort -u || true)"

  for pkg in "$@"; do
    base="${pkg%.i686}"

    if grep -Fxq "$base" <<<"$names" || pkg_available "$base"; then
      FOUND_PKGS+=("$pkg")
    else
      MISSING_PKGS+=("$pkg")
    fi
  done
}

# Instala a lista; se o lote falhar, tenta um por um.
dnf_install_list() {
  [[ $# -eq 0 ]] && return 0

  if sudo dnf install -y "$@"; then
    return 0
  fi

  warn "Instalação em lote falhou; tentando pacote por pacote..."

  local pkg failed=()

  for pkg in "$@"; do
    if ! sudo dnf install -y "$pkg"; then
      failed+=("$pkg")
    fi
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    WARNINGS+=("Falha ao instalar: ${failed[*]}")
    warn "Falha ao instalar: ${failed[*]}"
  fi
}

# Valida, avisa sobre os ausentes e instala o resto.
install_dnf_packages() {
  local label="$1"
  shift

  classify_packages "$@"

  if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    echo
    warn "Pacotes não encontrados (${label}):"

    local pkg
    for pkg in "${MISSING_PKGS[@]}"; do
      echo -e "  ${RED}•${RESET} $pkg"
    done
    echo

    WARNINGS+=("Pacotes não encontrados (${label}): ${MISSING_PKGS[*]}")
  fi

  [[ ${#FOUND_PKGS[@]} -eq 0 ]] && return 0

  info "Instalando pacotes (${label})..."
  dnf_install_list "${FOUND_PKGS[@]}"
}

# Instala o primeiro nome disponível entre as alternativas.
install_one_of() {
  local cand

  for cand in "$@"; do
    if pkg_available "$cand" && sudo dnf install -y "$cand"; then
      success "$cand instalado."
      return 0
    fi
  done

  return 1
}

enable_copr() {
  sudo dnf copr enable -y "$1"
}

disable_copr() {
  sudo dnf copr disable -y "$1" || true
}

# install_pkg_with_coprs "<alt1 alt2 ...>" <copr>...
# Tenta os repositórios já ativos; se não achar, habilita cada COPR em ordem.
install_pkg_with_coprs() {
  local candidates="$1"
  shift

  local -a cands
  read -r -a cands <<<"$candidates"

  local copr

  if install_one_of "${cands[@]}"; then
    return 0
  fi

  for copr in "$@"; do
    info "Tentando COPR $copr para: ${cands[*]}"

    if enable_copr "$copr"; then
      if install_one_of "${cands[@]}"; then
        return 0
      fi
      disable_copr "$copr"
    fi
  done

  WARNINGS+=("Não foi possível instalar (${cands[*]}). COPRs tentados: $*. Instale manualmente.")
  warn "Não foi possível instalar: ${cands[*]}"
  return 1
}

# version_ge A B  ->  0 se A >= B
version_ge() {
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

# ============================================================
# SISTEMA / DNF / REPOSITÓRIOS
# ============================================================

ensure_sudo() {
  info "Verificando sudo..."
  sudo -v || die "sudo é necessário para continuar."
}

tune_dnf() {
  if [[ -f /etc/dnf/dnf.conf ]] && ! grep -q '^max_parallel_downloads' /etc/dnf/dnf.conf; then
    info "Ajustando downloads paralelos do dnf..."
    echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf >/dev/null
  fi
}

sync_system_once() {
  info "Atualizando o sistema e sincronizando os repositórios uma vez..."
  sudo dnf upgrade --refresh -y
  DNF_SYNCED=1
}

# O comando "dnf copr" não vem no Fedora Minimal.
ensure_copr_support() {
  if dnf copr --help &>/dev/null; then
    success "Suporte a COPR disponível."
    return 0
  fi

  info "Instalando o plugin de COPR..."

  if sudo dnf install -y dnf5-plugins || sudo dnf install -y dnf-plugins-core; then
    success "Plugin de COPR instalado."
  else
    die "Não foi possível instalar o suporte a COPR (dnf5-plugins)."
  fi
}

enable_rpmfusion() {
  local ver
  ver="$(rpm -E %fedora)"

  if rpm -q rpmfusion-free-release rpmfusion-nonfree-release &>/dev/null; then
    success "RPM Fusion já está habilitado."
    return 0
  fi

  info "Habilitando RPM Fusion (free e nonfree)..."

  if sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${ver}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${ver}.noarch.rpm"; then
    success "RPM Fusion habilitado."
  else
    WARNINGS+=("RPM Fusion não habilitado: unrar, discord, telegram, vlc, steam e codecs completos ficarão indisponíveis.")
    warn "Falha ao habilitar o RPM Fusion."
  fi
}

# Terra (Fyra Labs): repositório rolling com pacotes que o Fedora não traz.
# Só o repositório base é habilitado; os subrepos (extras, mesa, nvidia,
# multimedia) conflitam com Fedora/RPM Fusion e ficam de fora de propósito.
# Como o pkg_available consulta todos os repositórios ativos, qualquer pacote
# que o Terra tiver passa a ser instalado de lá automaticamente.
enable_terra() {
  if [[ "$ENABLE_TERRA" != "1" ]]; then
    warn "ENABLE_TERRA=0: repositório Terra não será habilitado."
    return 0
  fi

  if rpm -q terra-release &>/dev/null; then
    success "Terra já está habilitado."
    return 0
  fi

  info "Habilitando o repositório Terra..."

  if sudo dnf install -y \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
    --setopt='terra.gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc' \
    terra-release ||
    sudo dnf install -y --nogpgcheck \
      --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
      terra-release; then
    success "Terra habilitado."
  else
    WARNINGS+=("Terra não habilitado: lazygit e awww cairão para binário/COPR. Veja developer.fyralabs.com/terra/installing")
    warn "Falha ao habilitar o Terra."
  fi
}

install_fedora_system_packages() {
  if [[ "$DNF_SYNCED" != "1" ]]; then
    die "Os repositórios do dnf ainda não foram sincronizados com atualização completa."
  fi

  install_dnf_packages "sistema" "${FEDORA_PKGS[@]}"
}

# ============================================================
# HYPRLAND (COPR com versão mínima)
# ============================================================

install_hyprshot() {
  if command -v hyprshot &>/dev/null; then
    success "hyprshot já está instalado."
    return 0
  fi

  if install_one_of hyprshot; then
    return 0
  fi

  info "hyprshot não está empacotado; baixando o script para /usr/local/bin..."

  if sudo curl -fsSL -o /usr/local/bin/hyprshot \
    https://raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot &&
    sudo chmod +x /usr/local/bin/hyprshot; then
    success "hyprshot instalado em /usr/local/bin."
  else
    WARNINGS+=("hyprshot não instalado. Baixe o script manualmente para /usr/local/bin.")
    warn "Falha ao instalar o hyprshot."
  fi
}

# Impede que um COPR "extra" substitua o Hyprland já instalado em upgrades.
protect_core_from_copr() {
  local copr="$1"
  local repo_id="copr:copr.fedorainfracloud.org:${copr//\//:}"
  local list="hyprland,hyprland-devel,hyprlock,hypridle,xdg-desktop-portal-hyprland"
  local repo_file="/etc/yum.repos.d/_${repo_id}.repo"

  if sudo dnf config-manager setopt "${repo_id}.excludepkgs=${list}" &>/dev/null; then
    return 0
  fi

  if [[ -f "$repo_file" ]]; then
    echo "excludepkgs=${list}" | sudo tee -a "$repo_file" >/dev/null
    return 0
  fi

  WARNINGS+=("Não foi possível proteger o Hyprland contra upgrades vindos de $copr (excludepkgs). Confira o repo manualmente.")
}

# hyprlock/hypridle normalmente vêm junto do Hyprland; o resto depende do COPR.
# O que faltar é procurado em HYPR_EXTRAS_COPR (com o núcleo protegido).
install_hypr_extras() {
  local pkg missing=() still=()

  for pkg in hyprlock hypridle hyprsunset hyprpicker hyprpolkitagent hyprshutdown; do
    if rpm -q "$pkg" &>/dev/null; then
      continue
    fi

    if ! install_one_of "$pkg"; then
      missing+=("$pkg")
    fi
  done

  local extras_copr before
  for extras_copr in "${HYPR_EXTRAS_COPRS[@]}"; do
    if [[ ${#missing[@]} -eq 0 ]]; then
      break
    fi

    if [[ "$extras_copr" == "$HYPRLAND_COPR_USED" ]]; then
      continue
    fi

    info "Procurando ${missing[*]} em $extras_copr..."

    if ! enable_copr "$extras_copr"; then
      warn "COPR $extras_copr indisponível para esta versão do Fedora."
      continue
    fi

    protect_core_from_copr "$extras_copr"
    before=${#missing[@]}
    still=()

    for pkg in "${missing[@]}"; do
      if ! install_one_of "$pkg"; then
        still+=("$pkg")
      fi
    done

    missing=("${still[@]}")

    # Nada veio desse COPR: não deixa ele ativo à toa.
    if [[ ${#missing[@]} -eq $before ]]; then
      disable_copr "$extras_copr"
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    WARNINGS+=("Sem pacote para: ${missing[*]}. Procure outro COPR ou compile do código-fonte.")
    warn "Sem pacote para: ${missing[*]}"
  fi

  install_hyprshot
}

# Maior versão de "hyprland" visível (opcionalmente restrita a um repo).
hyprland_candidate_version() {
  local repo_id="${1:-}" version=""

  if [[ -n "$repo_id" ]]; then
    version="$(dnf repoquery --quiet --repo "$repo_id" --latest-limit=1 --qf '%{version}\n' hyprland 2>/dev/null | sort -V | tail -n1 || true)"
  fi

  if [[ -z "$version" ]]; then
    version="$(dnf repoquery --quiet --latest-limit=1 --qf '%{version}\n' hyprland 2>/dev/null | sort -V | tail -n1 || true)"
  fi

  echo "$version"
}

install_hyprland() {
  info "Instalando Hyprland (mínimo exigido: ${HYPRLAND_MIN_VERSION})..."

  local installed
  if rpm -q hyprland &>/dev/null; then
    installed="$(rpm -q --qf '%{VERSION}\n' hyprland)"

    if version_ge "$installed" "$HYPRLAND_MIN_VERSION"; then
      success "Hyprland $installed já instalado."
      install_hypr_extras
      return 0
    fi

    warn "Hyprland $installed é mais antigo que o mínimo (${HYPRLAND_MIN_VERSION})."
  fi

  local candidate copr repo_id
  local -a coprs

  if [[ -n "${HYPRLAND_COPR:-}" ]]; then
    coprs=("$HYPRLAND_COPR")
  else
    # 1) Repositórios do próprio Fedora, se já tiverem versão boa.
    candidate="$(hyprland_candidate_version)"

    if [[ -n "$candidate" ]] && version_ge "$candidate" "$HYPRLAND_MIN_VERSION"; then
      info "Hyprland $candidate encontrado nos repositórios atuais."

      if sudo dnf install -y hyprland; then
        install_one_of xdg-desktop-portal-hyprland || WARNINGS+=("xdg-desktop-portal-hyprland não instalado.")
        HYPRLAND_COPR_USED="repositórios do Fedora"
        success "Hyprland instalado."
        install_hypr_extras
        return 0
      fi
    fi

    coprs=("${HYPRLAND_COPRS[@]}")
  fi

  # 2) COPRs, em ordem; vence o primeiro com versão >= mínima.
  for copr in "${coprs[@]}"; do
    info "Testando COPR do Hyprland: $copr"

    if ! enable_copr "$copr"; then
      warn "COPR $copr indisponível para esta versão do Fedora."
      continue
    fi

    repo_id="copr:copr.fedorainfracloud.org:${copr//\//:}"
    candidate="$(hyprland_candidate_version "$repo_id")"

    if [[ -z "$candidate" ]]; then
      warn "COPR $copr não tem o pacote hyprland para esta versão."
      disable_copr "$copr"
      continue
    fi

    if ! version_ge "$candidate" "$HYPRLAND_MIN_VERSION"; then
      warn "COPR $copr está em $candidate (< ${HYPRLAND_MIN_VERSION})."
      disable_copr "$copr"
      continue
    fi

    info "Instalando Hyprland $candidate a partir de $copr..."

    if sudo dnf install -y hyprland xdg-desktop-portal-hyprland; then
      HYPRLAND_COPR_USED="$copr"
      success "Hyprland $candidate instalado ($copr)."
      install_hypr_extras
      return 0
    fi

    warn "Falha ao instalar o Hyprland a partir de $copr."
    disable_copr "$copr"
  done

  WARNINGS+=("Hyprland NÃO instalado: nenhum COPR testado (${coprs[*]}) tinha versão >= ${HYPRLAND_MIN_VERSION}. Defina HYPRLAND_COPR=dono/projeto ou compile do código-fonte.")
  warn "Hyprland não instalado."
}

# ============================================================
# QUICKSHELL, MATUGEN, CLIPHIST
# ============================================================

install_shell_stack() {
  info "Instalando Quickshell, matugen e cliphist..."

  install_pkg_with_coprs "quickshell quickshell-git" \
    avengemedia/danklinux errornointernet/quickshell || true

  install_pkg_with_coprs "matugen" \
    avengemedia/danklinux heus-sueh/packages || true

  install_pkg_with_coprs "cliphist" \
    avengemedia/danklinux wef/cliphist || true
}

# ============================================================
# FERRAMENTAS SEM PACOTE NO FEDORA
#
# starship e lazygit: binário oficial do GitHub (/usr/local/bin)
# nwg-look e rnnoise: COPR
# ============================================================

# Restringe um repositório a certos pacotes, para um COPR grande não
# "assumir" pacotes do Fedora nos próximos upgrades.
restrict_repo_to() {
  local repo_id="$1"
  shift

  local list repo_file="/etc/yum.repos.d/_${repo_id}.repo"
  list="$(
    IFS=,
    echo "$*"
  )"

  if sudo dnf config-manager setopt "${repo_id}.includepkgs=${list}" &>/dev/null; then
    return 0
  fi

  if [[ -f "$repo_file" ]]; then
    echo "includepkgs=${list}" | sudo tee -a "$repo_file" >/dev/null
    return 0
  fi

  WARNINGS+=("Não foi possível restringir o repositório ${repo_id} a: ${list}.")
  return 1
}

install_starship() {
  if command -v starship &>/dev/null; then
    success "starship já está instalado."
    return 0
  fi

  if install_one_of starship; then
    return 0
  fi

  if [[ "$(uname -m)" != "x86_64" ]]; then
    WARNINGS+=("starship não instalado (arquitetura $(uname -m)). Veja https://starship.rs")
    return 0
  fi

  info "starship não está nos repositórios; baixando o binário oficial..."

  local tmp
  tmp="$(mktemp -d)"

  if curl -fsSL -o "$tmp/starship.tar.gz" \
    https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz &&
    tar -xzf "$tmp/starship.tar.gz" -C "$tmp" starship &&
    sudo install -Dm755 "$tmp/starship" /usr/local/bin/starship; then
    success "starship instalado em /usr/local/bin."
  else
    WARNINGS+=("starship não instalado. Veja https://starship.rs (script oficial de instalação).")
    warn "Falha ao instalar o starship."
  fi

  rm -rf "$tmp"
}

install_lazygit() {
  if command -v lazygit &>/dev/null; then
    success "lazygit já está instalado."
    return 0
  fi

  if install_one_of lazygit; then
    return 0
  fi

  if [[ "$(uname -m)" != "x86_64" ]]; then
    WARNINGS+=("lazygit não instalado (arquitetura $(uname -m)).")
    return 0
  fi

  info "lazygit não está nos repositórios; baixando o binário oficial..."

  local tmp version
  tmp="$(mktemp -d)"

  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null |
    jq -r '.tag_name // empty' | sed 's/^v//' || true)"

  if [[ -n "$version" ]] &&
    curl -fsSL -o "$tmp/lazygit.tar.gz" \
      "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz" &&
    tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit &&
    sudo install -Dm755 "$tmp/lazygit" /usr/local/bin/lazygit; then
    success "lazygit $version instalado em /usr/local/bin."
  else
    WARNINGS+=("lazygit não instalado. Baixe o binário em github.com/jesseduffield/lazygit/releases.")
    warn "Falha ao instalar o lazygit."
  fi

  rm -rf "$tmp"
}

install_nwg_look() {
  if command -v nwg-look &>/dev/null; then
    success "nwg-look já está instalado."
    return 0
  fi

  install_pkg_with_coprs "nwg-look" lbarrys/nwg-look tofik/nwg-shell || true
}

# O pacote do Fedora (via COPR) se chama ladspa-noise-suppression-for-voice.
# O caminho esperado pela config do PipeWire é /usr/lib/ladspa/librnnoise_ladspa.so;
# se o RPM instalar em outro lugar (ex.: /usr/lib64/ladspa), cria um symlink.
install_noise_suppression() {
  local pkg="ladspa-noise-suppression-for-voice" repo_id so

  info "Instalando supressão de ruído (rnnoise) para o PipeWire..."

  if ! rpm -q "$pkg" &>/dev/null; then
    install_pkg_with_coprs "$pkg noise-suppression-for-voice" ycollet/audinux ycollet/linuxmao || return 0

    pkg="$(rpm -qa 'ladspa-noise-suppression-for-voice' 'noise-suppression-for-voice' | head -n1 || true)"
    [[ -n "$pkg" ]] || return 0

    # O COPR do ycollet é enorme: limita ele ao pacote instalado.
    repo_id="$(dnf repoquery --installed --qf '%{from_repo}\n' "$pkg" 2>/dev/null | head -n1 || true)"
    if [[ "$repo_id" == copr:* ]]; then
      restrict_repo_to "$repo_id" "$pkg" || true
    fi
  fi

  so="$(rpm -ql "$pkg" 2>/dev/null | grep 'librnnoise_ladspa\.so$' | head -n1 || true)"

  if [[ -z "$so" ]]; then
    WARNINGS+=("librnnoise_ladspa.so não encontrado no pacote instalado; ajuste o caminho em pipewire.conf.d/99-input-denoising.conf.")
    return 0
  fi

  if [[ "$so" != "/usr/lib/ladspa/librnnoise_ladspa.so" ]]; then
    sudo mkdir -p /usr/lib/ladspa
    sudo ln -sf "$so" /usr/lib/ladspa/librnnoise_ladspa.so
    success "Symlink criado: /usr/lib/ladspa/librnnoise_ladspa.so -> $so"
  fi
}

install_extra_tools() {
  install_starship
  install_lazygit
  install_nwg_look
  install_noise_suppression
}

# ============================================================
# AWWW (wallpaper): COPR -> código-fonte -> swaybg
# ============================================================

build_awww_from_source() {
  info "Compilando o awww a partir do código-fonte (Rust)..."

  dnf_install_list rust cargo gcc make pkgconf-pkg-config wayland-devel wayland-protocols-devel git

  local tmp tag name found=0
  tmp="$(mktemp -d)"

  tag="$AWWW_GIT_REF"
  if [[ -z "$tag" ]]; then
    tag="$(git ls-remote --tags --refs --sort='-v:refname' "$AWWW_GIT_URL" 'v*' 2>/dev/null |
      head -n1 | sed 's|.*refs/tags/||' || true)"
  fi

  if [[ -n "$tag" ]]; then
    info "Usando a tag $tag do awww."
  else
    warn "Nenhuma tag encontrada; usando a branch padrão do awww."
  fi

  if ! git clone --depth 1 ${tag:+--branch "$tag"} "$AWWW_GIT_URL" "$tmp/awww"; then
    rm -rf "$tmp"
    return 1
  fi

  if ! (cd "$tmp/awww" && cargo build --release); then
    rm -rf "$tmp"
    return 1
  fi

  # /usr/local/bin está sempre no PATH da sessão (~/.local/bin não está).
  for name in awww awww-daemon swww swww-daemon; do
    if [[ -x "$tmp/awww/target/release/$name" ]]; then
      sudo install -Dm755 "$tmp/awww/target/release/$name" "/usr/local/bin/$name"
      found=1
    fi
  done

  rm -rf "$tmp"

  [[ "$found" == "1" ]] || return 1

  # Releases antigas geravam só swww*; as configs usam awww*.
  if [[ ! -x /usr/local/bin/awww && -x /usr/local/bin/swww ]]; then
    sudo ln -sf /usr/local/bin/swww /usr/local/bin/awww
    sudo ln -sf /usr/local/bin/swww-daemon /usr/local/bin/awww-daemon
  fi

  return 0
}

install_awww() {
  if command -v awww &>/dev/null; then
    success "awww já está instalado."
    return 0
  fi

  info "Instalando awww..."

  if install_pkg_with_coprs "awww" scottames/awww; then
    return 0
  fi

  # O install_pkg_with_coprs já registrou um aviso; o build vira a 2ª tentativa.
  if build_awww_from_source; then
    success "awww compilado e instalado em /usr/local/bin."
    return 0
  fi

  if install_one_of swaybg; then
    WARNINGS+=("awww indisponível: instalado swaybg como fallback. Ajuste o WallpaperManager do Quickshell e o autostart do Hyprland para o novo gerenciador.")
  else
    WARNINGS+=("awww indisponível e sem fallback instalado. Ajuste o WallpaperManager do Quickshell e o autostart do Hyprland.")
  fi
}

# ============================================================
# FONTES SEM PACOTE OFICIAL
# ============================================================

install_fonts_extra() {
  local font_dir="$HOME/.local/share/fonts"
  local tmp

  mkdir -p "$font_dir"

  if fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd'; then
    success "JetBrainsMono Nerd Font já instalada."
  else
    info "Instalando JetBrainsMono Nerd Font..."
    tmp="$(mktemp -d)"

    if curl -fsSL -o "$tmp/JetBrainsMono.tar.xz" \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz &&
      mkdir -p "$font_dir/JetBrainsMonoNerd" &&
      tar -xJf "$tmp/JetBrainsMono.tar.xz" -C "$font_dir/JetBrainsMonoNerd"; then
      success "JetBrainsMono Nerd Font instalada."
    else
      WARNINGS+=("Não foi possível baixar a JetBrainsMono Nerd Font (nerd-fonts releases).")
      warn "Falha ao instalar a JetBrainsMono Nerd Font."
    fi

    rm -rf "$tmp"
  fi

  if fc-list 2>/dev/null | grep -qi 'Material Symbols'; then
    success "Material Symbols já instalada."
  else
    info "Instalando Material Symbols (variable)..."
    mkdir -p "$font_dir/MaterialSymbols"

    local style base failed=0
    base="https://github.com/google/material-design-icons/raw/master/variablefont"

    for style in Outlined Rounded Sharp; do
      if ! curl -fsSL \
        -o "$font_dir/MaterialSymbols/MaterialSymbols${style}[FILL,GRAD,opsz,wght].ttf" \
        "${base}/MaterialSymbols${style}%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"; then
        failed=1
      fi
    done

    if [[ "$failed" == "1" ]]; then
      WARNINGS+=("Material Symbols: falha no download (google/material-design-icons, pasta variablefont). Os ícones do Quickshell podem não aparecer.")
      warn "Falha ao baixar a Material Symbols."
    else
      success "Material Symbols instalada."
    fi
  fi

  fc-cache -f "$font_dir" >/dev/null 2>&1 || true
}

# ============================================================
# APPS (com fallback para Flatpak) E GRUPOS OPCIONAIS
# ============================================================

configure_flatpak() {
  info "Configurando Flathub para o usuário atual..."
  flatpak remote-add --if-not-exists --user flathub \
    https://flathub.org/repo/flathub.flatpakrepo
  success "Flatpak pronto para instalar aplicativos do Flathub."
}

install_apps() {
  classify_packages "${FEDORA_APPS[@]}"

  local -a missing_apps=("${MISSING_PKGS[@]}")
  local -a found_apps=("${FOUND_PKGS[@]}")
  local app

  if [[ ${#found_apps[@]} -gt 0 ]]; then
    info "Instalando aplicativos..."
    dnf_install_list "${found_apps[@]}"
  fi

  for app in "${missing_apps[@]}"; do
    if [[ -n "${FLATPAK_FALLBACKS[$app]:-}" ]]; then
      info "$app não está nos repositórios; instalando via Flathub..."

      if flatpak install --user -y flathub "${FLATPAK_FALLBACKS[$app]}"; then
        success "$app instalado via Flatpak (${FLATPAK_FALLBACKS[$app]})."
      else
        WARNINGS+=("Falha ao instalar $app via Flatpak (${FLATPAK_FALLBACKS[$app]}).")
      fi
    else
      WARNINGS+=("App não encontrado: $app")
      warn "App não encontrado: $app"
    fi
  done
}

install_optional_group() {
  local group_name="$1"
  local group_variable="$2"
  local -n group_packages="$group_variable"
  local response

  [[ ${#group_packages[@]} -eq 0 ]] && return 0

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

install_optional_fedora_packages() {
  install_optional_group "Jogos (Steam, Proton, ferramentas)" OPTIONAL_GAMING_PKGS

  if [[ ${#OPTIONAL_SELECTED_PKGS[@]} -eq 0 ]]; then
    return
  fi

  install_dnf_packages "jogos" "${OPTIONAL_SELECTED_PKGS[@]}"
  success "Grupos opcionais processados."
}

# ============================================================
# GPU
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
  # Atenção: "VGA compatible controller" contém "ati"; por isso a busca por
  # AMD/ATI usa limites de palavra e nomes de marca.
  if echo "$gpu_info" | grep -qiE 'virtio|qxl|vmware|bochs|cirrus|red hat'; then
    GPU_VENDOR="virtual"
  elif echo "$gpu_info" | grep -qiE '\bAMD\b|\bATI\b|Radeon|Advanced Micro Devices'; then
    GPU_VENDOR="amd"
  elif echo "$gpu_info" | grep -qi 'NVIDIA'; then
    GPU_VENDOR="nvidia"
  elif echo "$gpu_info" | grep -qi 'Intel'; then
    GPU_VENDOR="intel"
  else
    GPU_VENDOR="unknown"
  fi

  case "$GPU_VENDOR" in
  virtual) success "GPU virtual detectada (VM)." ;;
  amd) success "GPU AMD detectada." ;;
  nvidia) success "GPU NVIDIA detectada." ;;
  intel) success "GPU Intel detectada." ;;
  *) warn "Fabricante da GPU não identificado." ;;
  esac
}

# Acrescenta ao grupo de jogos as libs 32-bit do driver detectado.
add_gpu_lib32_to_gaming() {
  case "$GPU_VENDOR" in
  amd | intel | virtual)
    OPTIONAL_GAMING_PKGS+=(mesa-dri-drivers.i686 mesa-vulkan-drivers.i686)
    ;;
  nvidia)
    OPTIONAL_GAMING_PKGS+=(xorg-x11-drv-nvidia-libs.i686)
    ;;
  esac
}

install_gpu_drivers() {
  case "$GPU_VENDOR" in
  virtual)
    info "GPU virtual detectada (VM): usando apenas o Mesa padrão."
    install_dnf_packages "GPU virtual" "${INTEL_PKGS[@]}"
    ;;

  amd)
    install_dnf_packages "GPU AMD" "${AMD_PKGS[@]}"

    # Decodificação H.264/H.265 por hardware exige a variante freeworld (RPM Fusion).
    info "Instalando codecs de hardware (mesa freeworld)..."
    sudo dnf install -y --allowerasing mesa-va-drivers-freeworld ||
      WARNINGS+=("mesa-va-drivers-freeworld não instalado (RPM Fusion ativo?). Decodificação por hardware pode ficar limitada.")

    # VDPAU é opcional e pode não existir nas versões mais novas do Mesa/Fedora.
    sudo dnf install -y --allowerasing mesa-vdpau-drivers-freeworld ||
      warn "mesa-vdpau-drivers-freeworld indisponível (opcional)."

    info "Instalando o ffmpeg completo (RPM Fusion)..."
    sudo dnf install -y --allowerasing ffmpeg ||
      WARNINGS+=("ffmpeg completo não instalado (RPM Fusion ativo?).")

    success "Stack gráfico AMD instalado."
    ;;

  intel)
    install_dnf_packages "GPU Intel" "${INTEL_PKGS[@]}"
    ;;

  nvidia)
    info "GPU NVIDIA detectada."
    warn "Drivers NVIDIA não serão instalados automaticamente."
    warn "Configure o driver NVIDIA conforme sua necessidade."
    WARNINGS+=("GPU NVIDIA: instale e configure o driver manualmente (RPM Fusion: akmod-nvidia).")
    ;;

  *)
    warn "Não foi possível determinar a GPU."
    warn "Nenhum driver específico será instalado."
    ;;
  esac
}

# ============================================================
# SERVIÇOS
# ============================================================

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
  ensure_system_service power-profiles-daemon.service
  ensure_system_service cups.socket

  ensure_user_service pipewire.socket
  ensure_user_service pipewire-pulse.socket
  ensure_user_service wireplumber.service

  # O Fedora já usa firewalld; ele não é alterado por este script.
}

# ============================================================
# DISPLAY MANAGER (Fedora Minimal não traz nenhum)
# ============================================================

setup_display_manager() {
  if [[ "$DISPLAY_MANAGER" == "none" ]]; then
    warn "DISPLAY_MANAGER=none: nenhum display manager será configurado."
    return 0
  fi

  local current_dm_service="" chosen=""

  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    current_dm_service=$(
      basename \
        "$(readlink -f /etc/systemd/system/display-manager.service)" \
        .service
    )
  fi

  # 1) Tenta o Ly (mesma escolha do install.sh); se não existir, usa o SDDM.
  if [[ "$DISPLAY_MANAGER" == "ly" ]]; then
    info "Tentando instalar o Ly..."

    if install_one_of ly; then
      chosen="ly"
    else
      warn "Ly não está disponível nos repositórios; usando SDDM."
    fi
  fi

  if [[ -z "$chosen" ]]; then
    info "Instalando SDDM..."

    if install_one_of sddm; then
      chosen="sddm"
    else
      WARNINGS+=("Nenhum display manager instalado. Inicie o Hyprland manualmente (start-hyprland ou Hyprland no TTY).")
      return 0
    fi
  fi

  # Se houver um DM diferente do escolhido, desabilita ele
  if [[ -n "$current_dm_service" && "$current_dm_service" != "$chosen" ]]; then
    info "Display manager atual detectado: $current_dm_service"
    warn "Desabilitando $current_dm_service para os próximos boots..."
    # Sem --now: o usuário pode estar nessa sessão.
    sudo systemctl disable "${current_dm_service}.service" || true
  fi

  case "$chosen" in
  ly)
    if systemctl list-unit-files --no-legend 'ly@.service' 2>/dev/null | grep -q .; then
      sudo systemctl enable ly@tty1.service
    elif systemctl list-unit-files --no-legend 'ly.service' 2>/dev/null | grep -q .; then
      sudo systemctl enable ly.service
    else
      WARNINGS+=("Ly instalado, mas nenhuma unit (ly@.service/ly.service) foi encontrada. Habilite manualmente.")
    fi
    ;;
  sddm)
    sudo systemctl enable sddm.service
    ;;
  esac

  # Instalações mínimas sobem em multi-user.target; sem isso o DM nunca inicia.
  sudo systemctl set-default graphical.target

  success "Display manager configurado: $chosen (graphical.target definido)."
}

# ============================================================
# FERRAMENTAS PYTHON (equivalentes dos pacotes AUR)
# ============================================================

install_kde_material_you_colors() {
  info "Instalando kde-material-you-colors com pipx..."

  local bin="$HOME/.local/bin/kde-material-you-colors"

  if ! command -v pipx &>/dev/null; then
    WARNINGS+=("kde-material-you-colors não instalado (pipx ausente). Rode: pipx install kde-material-you-colors")
    return 0
  fi

  if pipx list --short 2>/dev/null | awk '{print $1}' | grep -qx kde-material-you-colors; then
    success "kde-material-you-colors já está instalado."
  elif ! pipx install kde-material-you-colors; then
    WARNINGS+=("Falha ao instalar kde-material-you-colors. Rode: pipx install kde-material-you-colors")
    warn "Falha ao instalar o kde-material-you-colors."
    return 0
  fi

  # Os post_hooks do matugen rodam na sessão do Hyprland, sem ~/.local/bin no PATH.
  if [[ -x "$bin" ]]; then
    sudo ln -sf "$bin" /usr/local/bin/kde-material-you-colors ||
      WARNINGS+=("Não foi possível criar /usr/local/bin/kde-material-you-colors.")
  fi
}

# ============================================================
# PYWALFOX (tema do Firefox via matugen)
#
# Instalação recomendada pelo projeto: pipx + `pywalfox install`.
# O add-on do Firefox precisa ser instalado manualmente.
# ============================================================

install_pywalfox() {
  info "Instalando Pywalfox com pipx..."

  local pywalfox_bin="$HOME/.local/bin/pywalfox"

  if ! command -v pipx &>/dev/null; then
    warn "pipx não encontrado; Pywalfox ignorado."
    WARNINGS+=("Pywalfox não instalado (pipx ausente). Rode: pipx install pywalfox && pywalfox install")
    return 0
  fi

  if pipx list --short 2>/dev/null | awk '{print $1}' | grep -qx pywalfox; then
    success "Pywalfox já está instalado."
  elif ! pipx install pywalfox; then
    warn "Falha ao instalar o Pywalfox com pipx."
    WARNINGS+=("Falha ao instalar o Pywalfox. Rode: pipx install pywalfox && pywalfox install")
    return 0
  fi

  if [[ ! -x "$pywalfox_bin" ]]; then
    warn "$pywalfox_bin não encontrado após a instalação."
    WARNINGS+=("Pywalfox: executável não encontrado em $pywalfox_bin.")
    return 0
  fi

  # O Firefox chama o host nativo como `pywalfox`, pelo PATH. A sessão do
  # Hyprland normalmente não inclui ~/.local/bin, então expomos o comando
  # em /usr/local/bin (que está sempre no PATH).
  if ! sudo ln -sf "$pywalfox_bin" /usr/local/bin/pywalfox; then
    WARNINGS+=("Não foi possível criar /usr/local/bin/pywalfox; o Firefox pode não achar o host nativo.")
  fi

  if "$pywalfox_bin" install; then
    success "Host nativo do Pywalfox registrado."
  else
    warn "Falha ao registrar o host nativo do Pywalfox."
    WARNINGS+=("Pywalfox: rode manualmente: pywalfox install")
  fi

  WARNINGS+=("Pywalfox: instale o add-on no Firefox (https://addons.mozilla.org/firefox/addon/pywalfox/) e reinicie o navegador.")
}

# Pacotes que existem só no AUR e não têm instalação automática aqui.
report_aur_only_packages() {
  WARNINGS+=(
    "Só no AUR (sem instalação automática no Fedora): breeze-plus, darkly, spotifast, zapfast. Hooks do matugen que dependem deles vão falhar até você instalá-los manualmente."
  )
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

  if ((conflict_count > 0)); then
    success "$conflict_count arquivo(s) salvo(s) em $backup_root antes da cópia."
  fi
}

# Substitui /home/ely pelo $HOME real nos arquivos copiados
# (quickshell/settings.json, gtk-3.0/bookmarks, etc.).
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

  # .config
  if [[ -d "$DOTFILES_SOURCE/.config" ]]; then
    mkdir -p "$HOME/.config"
    backup_dotfile_conflicts "$DOTFILES_SOURCE/.config" "$HOME/.config"

    cp -r "$DOTFILES_SOURCE/.config/." "$HOME/.config/"
    fix_hardcoded_paths "$DOTFILES_SOURCE/.config"

    success ".config copiado para $HOME."
  else
    warn ".config não encontrado em: $DOTFILES_SOURCE"
  fi

  # Temas de cursor (XCursor-Pro-Dark e a versão hyprcursor)
  if [[ -d "$DOTFILES_SOURCE/.local/share/icons" ]]; then
    mkdir -p "$HOME/.local/share/icons"
    backup_dotfile_conflicts "$DOTFILES_SOURCE/.local/share/icons" "$HOME/.local/share/icons"

    cp -r "$DOTFILES_SOURCE/.local/share/icons/." "$HOME/.local/share/icons/"

    success "Temas de cursor copiados."
  else
    warn "Temas de cursor não encontrados em: $DOTFILES_SOURCE/.local/share/icons"
  fi

  # Pictures
  if [[ -d "$DOTFILES_SOURCE/Pictures" ]]; then
    mkdir -p "$HOME/Pictures"
    backup_dotfile_conflicts "$DOTFILES_SOURCE/Pictures" "$HOME/Pictures"

    cp -r "$DOTFILES_SOURCE/Pictures/." "$HOME/Pictures/"

    success "Pictures copiado."
  else
    warn "Pictures não encontrado."
  fi
}

# Gera as cores pela primeira vez com o wallpaper inicial, para o primeiro
# boot já ter o tema. O apply_colors.sh do Quickshell cria o
# .current-wallpaper.png, roda o matugen e dispara os hooks (kitty, gtk, kde...).
seed_wallpaper() {
  local wall_dir="$HOME/Pictures/Wallpapers"
  local current="$wall_dir/.current-wallpaper.png"
  local seed="$wall_dir/wallhaven-pomle9.jpg"
  local apply_colors="$HOME/.config/quickshell/scripts/apply_colors.sh"

  if [[ -f "$current" ]]; then
    success "Wallpaper atual já existe."
    return 0
  fi

  if [[ ! -f "$seed" ]]; then
    warn "Wallpaper inicial não encontrado: $seed"
    return 0
  fi

  if [[ ! -x "$apply_colors" ]]; then
    warn "apply_colors.sh não encontrado em $apply_colors."
    WARNINGS+=("Cores iniciais não geradas. Escolha um wallpaper pelo Quickshell (SUPER+W).")
    return 0
  fi

  info "Gerando cores iniciais com o wallpaper padrão..."
  if "$apply_colors" "$seed"; then
    success "Cores geradas."
  else
    WARNINGS+=("apply_colors.sh terminou com erro; confira se o matugen está instalado.")
  fi
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

# ============================================================
# Fluxo de instalação
# ============================================================

install_dependencies() {
  info "Iniciando instalação para Fedora..."

  ensure_sudo
  tune_dnf
  sync_system_once
  ensure_copr_support
  enable_rpmfusion
  enable_terra

  install_fedora_system_packages
  install_extra_tools

  detect_gpu
  add_gpu_lib32_to_gaming

  install_hyprland
  install_shell_stack
  install_awww
  install_fonts_extra

  configure_flatpak
  install_apps

  install_optional_fedora_packages
  install_gpu_drivers

  ensure_essential_services
  setup_display_manager

  install_kde_material_you_colors
  install_pywalfox
  report_aur_only_packages
}

update_configuration() {
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
  echo -e "${BOLD}Dotfiles Installer (Fedora)${RESET}"
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
