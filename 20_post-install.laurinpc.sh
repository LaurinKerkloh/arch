#!/bin/bash

set -e

#
# Setup the NVIDIA driver
#

# Remove the kms hook from the initramfs.
# "This will prevent the initramfs from containing the nouveau module making sure the kernel cannot load it during early boot."
sudo sed -i '/^HOOKS=(/s/ kms//' /etc/mkinitcpio.conf

# Add the nvidia modules to the initramfs
# Disabled this for now as it seems to cause a kernel panic when resuming from suspend
# sudo sed -i '/^MODULES=(/s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

# Set the DRM kernel mode setting kernel parameter
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/s/"$/ nvidia-drm.modeset=1"/' /etc/default/grub

# Regenerate the initramfs and the GRUB configuration
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

#
# Backlight control using ddcutil
#
sudo usermod -aG i2c $USER
cat <<EOF | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
i2c-dev
EOF
