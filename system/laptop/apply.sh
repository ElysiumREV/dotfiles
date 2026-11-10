#!/usr/bin/env bash
# Laptop power tweaks. Safe to re-run. Usage: ./system/laptop/apply.sh
# (serviços sob demanda ficam em system/common/apply.sh)
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

if ! ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
  echo "Sem bateria detectada, nada a fazer (desktop)."
  exit 0
fi

echo "==> Copiando regras udev e sysctl para /etc"
sudo install -Dm644 etc/udev/rules.d/50-pci-runtime-pm.rules /etc/udev/rules.d/50-pci-runtime-pm.rules
sudo install -Dm644 etc/sysctl.d/90-laptop-power.conf /etc/sysctl.d/90-laptop-power.conf
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=pci --action=change
sudo sysctl --quiet --system

echo "==> power-profiles-daemon: ABM do painel e DPM da GPU no power-saver"
if command -v powerprofilesctl >/dev/null; then
  sudo powerprofilesctl configure-action amdgpu_panel_power --enable 2>/dev/null || true
  sudo powerprofilesctl configure-action amdgpu_dpm --enable 2>/dev/null || true
  powerprofilesctl list-actions | grep -E "Name|Enabled"
fi

echo "Pronto."
