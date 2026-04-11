#!/bin/bash

set -ex

# Plymouth
sudo pacman -S --noconfirm --needed plymouth
if ! grep -Eq '^HOOKS=.*plymouth' /etc/mkinitcpio.conf; then
  # Backup original mkinitcpio.conf just in case
  backup_timestamp=$(date +"%Y%m%d%H%M%S")
  sudo cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.bak.${backup_timestamp}"

  # Add plymouth to HOOKS array after 'base udev' or 'base systemd'
  if grep "^HOOKS=" /etc/mkinitcpio.conf | grep -q "base systemd"; then
    sudo sed -i '/^HOOKS=/s/base systemd/base systemd plymouth/' /etc/mkinitcpio.conf
  elif grep "^HOOKS=" /etc/mkinitcpio.conf | grep -q "base udev"; then
    sudo sed -i '/^HOOKS=/s/base udev/base udev plymouth/' /etc/mkinitcpio.conf
  else
    echo "Couldn't add the Plymouth hook"
  fi

  # Regenerate initramfs
  sudo mkinitcpio -P
fi

for entry in /boot/loader/entries/*.conf; do
  if [ -f "$entry" ]; then
    # Skip fallback entries
    if [[ "$(basename "$entry")" == *"fallback"* ]]; then
      echo "Skipped: $(basename "$entry") (fallback entry)"
      continue
    fi

    # Skip if splash it already present for some reason
    if ! grep -q "splash" "$entry"; then
      sudo sed -i '/^options/ s/$/ splash quiet/' "$entry"
    else
      echo "Skipped: $(basename "$entry") (splash already present)"
    fi
  fi
done

sudo cp -r $HOME/.local/share/catppuccin-plymouth/themes/catppuccin-mocha/ /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R catppuccin-mocha

if [ ! -x /usr/local/bin/seamless-login ]; then
  # Compile the seamless login helper -- needed to prevent seeing terminal between loader and desktop
  gcc -o seamless-login ./seamless-login.c
  sudo mv seamless-login /usr/local/bin/seamless-login
  sudo chmod +x /usr/local/bin/seamless-login
fi

if [ ! -f /etc/systemd/system/seamless-login.service ]; then
  sudo tee /etc/systemd/system/seamless-login.service <<EOF
[Unit]
Description=Seamless Auto-Login
Conflicts=getty@tty1.service
After=systemd-user-sessions.service getty@tty1.service plymouth-quit.service systemd-logind.service
PartOf=graphical.target

[Service]
Type=simple
ExecStart=/usr/local/bin/seamless-login uwsm start -- hyprland.desktop
Restart=always
RestartSec=2
User=$USER_NAME
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
StandardInput=tty
StandardOutput=journal
StandardError=journal+console
PAMName=login

[Install]
WantedBy=graphical.target
EOF
fi

if [ ! -f /etc/systemd/system/plymouth-quit.service.d/wait-for-graphical.conf ]; then
  # Make plymouth remain until graphical.target
  sudo mkdir -p /etc/systemd/system/plymouth-quit.service.d
  sudo tee /etc/systemd/system/plymouth-quit.service.d/wait-for-graphical.conf <<'EOF'
[Unit]
After=multi-user.target
EOF
fi

# Mask plymouth-quit-wait.service only if not already masked
if ! systemctl is-enabled plymouth-quit-wait.service | grep -q masked; then
  sudo systemctl mask plymouth-quit-wait.service
  sudo systemctl daemon-reload
fi

# Enable seamless-login.service only if not already enabled
if ! systemctl is-enabled seamless-login.service | grep -q enabled; then
  sudo systemctl enable seamless-login.service
fi

# Disable getty@tty1.service only if not already disabled
if ! systemctl is-enabled getty@tty1.service | grep -q disabled; then
  sudo systemctl disable getty@tty1.service
fi
