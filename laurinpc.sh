#!/bin/bash

set -ex

sudo pacman -S --noconfirm --needed ddcutil

if [ ! -e "/etc/modules-load.d/nct6775.conf" ]; then
    echo nct6775 | sudo tee /etc/modules-load.d/nct6775.conf
    echo "options nct6775 force_id=0xd802" | sudo tee /etc/modprobe.d/nct6775.conf
fi

sudo systemctl unmask systemd-networkd-wait-online.service
sudo systemctl enable systemd-networkd-wait-online.service

sudo sed -i '/^\s*RequiredForOnline\s*=/c\RequiredForOnline=unmanaged' /etc/systemd/network/20-wlan.network
sudo sed -i '/^\s*RequiredForOnline\s*=/c\RequiredForOnline=unmanaged' /etc/systemd/network/20-wwan.network
