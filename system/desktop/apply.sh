#!/usr/bin/env bash
# Desktop performance tweaks. Safe to re-run. Usage: ./system/desktop/apply.sh
#   - sched-ext (scx_lavd via scx_loader)
#   - ananicy-cpp com as regras do CachyOS
#   - gamemode (renice + clock máximo da GPU AMD durante o jogo)
#   - sysctl
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
  echo "Bateria detectada, nada a fazer (notebook usa system/laptop)."
  exit 0
fi

echo "==> Instalando pacotes"
sudo pacman -S --needed --noconfirm scx-scheds scx-tools ananicy-cpp gamemode lib32-gamemode
# Regras do ananicy: repo do CachyOS se existir, senão AUR
if pacman -Si cachyos-ananicy-rules >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm cachyos-ananicy-rules
elif ! pacman -Qq cachyos-ananicy-rules cachyos-ananicy-rules-git >/dev/null 2>&1 &&
  command -v paru >/dev/null; then
  paru -S --needed --noconfirm cachyos-ananicy-rules-git
fi

echo "==> Copiando sysctl, scx_loader e gamemode para /etc"
sudo install -Dm644 etc/sysctl.d/90-desktop-performance.conf /etc/sysctl.d/90-desktop-performance.conf
sudo install -Dm644 etc/scx_loader.toml /etc/scx_loader.toml
sudo sysctl --quiet --system

# gamemode precisa do índice da GPU AMD (cardN); sem AMD a seção [gpu] sai.
# Com mais de uma AMD (APU + placa dedicada), fica a de maior VRAM: o vídeo
# integrado só tem uma fatia pequena da RAM, a dedicada tem bem mais.
gpu="" best_vram=-1
for card in /sys/class/drm/card*; do
  [[ ${card##*/} =~ ^card[0-9]+$ ]] || continue # pula conectores (card0-DP-1...)
  [[ $(<"$card/device/vendor") == 0x1002 ]] || continue
  vram=$(cat "$card/device/mem_info_vram_total" 2>/dev/null || echo 0)
  if ((vram > best_vram)); then
    best_vram=$vram
    gpu=${card##*card}
  fi
done
if [[ -n $gpu ]]; then
  sed "s/@GPU_DEVICE@/$gpu/" etc/gamemode/gamemode.ini
else
  sed '/^\[gpu\]/,$d' etc/gamemode/gamemode.ini
fi | sudo install -Dm644 /dev/stdin /etc/gamemode.ini

echo "==> Serviços"
sudo systemctl enable --now scx_loader.service ananicy-cpp.service
# reinicia para pegar config nova em re-execuções
sudo systemctl restart scx_loader.service ananicy-cpp.service

if ! id -nG "$USER" | grep -qw gamemode; then
  sudo usermod -aG gamemode "$USER"
  echo "Adicionado ao grupo gamemode: faça logout/login para valer."
fi

echo "==> Estado"
echo "sched-ext: $(cat /sys/kernel/sched_ext/state 2>/dev/null) ($(cat /sys/kernel/sched_ext/root/ops 2>/dev/null))"
echo "Pronto."
