#!/usr/bin/env bash
# Laptop power tweaks. Safe to re-run. Usage: ./system/laptop/apply.sh
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

if ! ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
  echo "Sem bateria detectada, nada a fazer (desktop)."
  exit 0
fi

echo "==> Copiando regras udev, sysctl, polkit e hook do pacman para /etc"
sudo install -Dm644 etc/udev/rules.d/50-pci-runtime-pm.rules /etc/udev/rules.d/50-pci-runtime-pm.rules
sudo install -Dm644 etc/sysctl.d/90-laptop-power.conf /etc/sysctl.d/90-laptop-power.conf
sudo install -Dm644 etc/polkit-1/rules.d/50-vpn-on-demand.rules /etc/polkit-1/rules.d/50-vpn-on-demand.rules
sudo install -Dm644 etc/pacman.d/hooks/proton-vpn-on-demand.hook /etc/pacman.d/hooks/proton-vpn-on-demand.hook
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=pci --action=change
sudo sysctl --quiet --system

echo "==> Serviços só sob demanda"
# CUPS e Avahi: ficam só os sockets (sobem quando algo usa a porta)
for unit in cups.service avahi-daemon.service; do
  systemctl cat "$unit" >/dev/null 2>&1 && sudo systemctl disable "$unit" || true
done
# cups.path starts cupsd at every boot (its trigger file always exists)
systemctl cat cups.path >/dev/null 2>&1 && sudo systemctl disable --now cups.path || true
for unit in cups.socket avahi-daemon.socket; do
  systemctl cat "$unit" >/dev/null 2>&1 && sudo systemctl enable "$unit" || true
done
# para o cupsd atual; o socket sobe ele de novo quando algo for imprimir
# (cups.socket tem PartOf=cups.service e para junto, então é religado em seguida)
if systemctl is-active --quiet cups.service; then
  sudo systemctl stop cups.service
  sudo systemctl start cups.socket
fi
# VPNs: não iniciam no boot. Proton sobe via D-Bus quando o app pede,
# o WARP (warp-svc) sobe pela função warp-cli do fish.
for unit in proton.VPN.service warp-svc.service; do
  systemctl cat "$unit" >/dev/null 2>&1 && sudo systemctl disable --now "$unit" || true
done

# Ícone de bandeja do WARP não é usado; mascarado para não aparecer
systemctl --user mask warp-taskbar.service >/dev/null 2>&1 || true

echo "==> power-profiles-daemon: ABM do painel e DPM da GPU no power-saver"
if command -v powerprofilesctl >/dev/null; then
  sudo powerprofilesctl configure-action amdgpu_panel_power --enable 2>/dev/null || true
  sudo powerprofilesctl configure-action amdgpu_dpm --enable 2>/dev/null || true
  powerprofilesctl list-actions | grep -E "Name|Enabled"
fi

echo "Pronto."
