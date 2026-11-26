#!/usr/bin/env bash
# Laptop power tweaks. Safe to re-run. Usage: ./system/laptop/apply.sh
# (serviços sob demanda ficam em system/common/apply.sh)
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

if ! ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
  echo "Sem bateria detectada, nada a fazer (desktop)."
  exit 0
fi

echo "==> Copiando regras udev, sysctl e modprobe para /etc"
sudo install -Dm644 etc/udev/rules.d/50-pci-runtime-pm.rules /etc/udev/rules.d/50-pci-runtime-pm.rules
sudo install -Dm644 etc/sysctl.d/90-laptop-power.conf /etc/sysctl.d/90-laptop-power.conf
sudo install -Dm644 etc/modprobe.d/btusb-no-autosuspend.conf /etc/modprobe.d/btusb-no-autosuspend.conf
sudo install -Dm644 etc/udev/rules.d/50-bt-no-autosuspend.rules /etc/udev/rules.d/50-bt-no-autosuspend.rules
sudo install -Dm644 etc/sysctl.d/90-zram.conf /etc/sysctl.d/90-zram.conf
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=pci --action=change
sudo udevadm trigger --subsystem-match=usb --attr-match=idVendor=0bda --attr-match=idProduct=4852 --action=change
sudo sysctl --quiet --system

echo "==> zram do tamanho da RAM (vale no próximo boot)"
# Não reinicia o zram aqui: isso desligaria o swap em uso e travaria tudo.
sudo install -Dm644 etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf

echo "==> Swapfile para hibernar (e reserva quando o zram enche)"
# Só ext4: em btrfs o swapfile precisa de subvolume próprio e outro offset.
SWAPFILE=/swapfile
if [[ "$(findmnt -no FSTYPE /)" == ext4 ]]; then
  # Pelo menos o tamanho da RAM, arredondado para cima em GiB, +2 GiB de folga.
  ram_gib=$(awk '/MemTotal/ {print int(($2 + 1048575) / 1048576)}' /proc/meminfo)
  swap_gib=$((ram_gib + 2))
  if [[ ! -f $SWAPFILE ]]; then
    sudo mkswap -U clear --size "${swap_gib}G" --file "$SWAPFILE"
  fi
  # Prioridade abaixo do zram (100): disco só depois que o zram encher.
  if ! grep -qE "^$SWAPFILE\s" /etc/fstab; then
    echo "$SWAPFILE none swap defaults,pri=10 0 0" | sudo tee -a /etc/fstab >/dev/null
  fi
  swapon --show=NAME --noheadings | grep -qx "$SWAPFILE" || sudo swapon -p 10 "$SWAPFILE"

  echo "==> Hibernação: hook resume no initramfs e resume= no GRUB"
  if ! grep -qE '^HOOKS=.*\bresume\b' /etc/mkinitcpio.conf; then
    sudo sed -i -E '/^HOOKS=/ s/\bfilesystems\b/resume filesystems/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
  fi
  root_uuid=$(findmnt -no UUID /)
  offset=$(sudo filefrag -v "$SWAPFILE" | awk '$1 == "0:" {sub(/\.\.$/, "", $4); print $4}')
  resume_args="resume=UUID=$root_uuid resume_offset=$offset"
  if ! grep -qF "$resume_args" /etc/default/grub; then
    # Tira resume antigos (offset muda se o swapfile for recriado) e põe o atual.
    sudo sed -i -E \
      -e '/^GRUB_CMDLINE_LINUX=/ s/ ?resume(_offset)?=[^ "]*//g' \
      -e "/^GRUB_CMDLINE_LINUX=/ s/\"\$/ $resume_args\"/" \
      /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
  echo "Hibernação pronta após reiniciar: systemctl hibernate"
else
  echo "Raiz não é ext4, swapfile/hibernação não configurados."
fi

echo "==> power-profiles-daemon: ABM do painel e DPM da GPU no power-saver"
if command -v powerprofilesctl >/dev/null; then
  sudo powerprofilesctl configure-action amdgpu_panel_power --enable 2>/dev/null || true
  sudo powerprofilesctl configure-action amdgpu_dpm --enable 2>/dev/null || true
  powerprofilesctl list-actions | grep -E "Name|Enabled"
fi

echo "Pronto."
