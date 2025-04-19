#!/bin/bash

set -e

# Ask for the sudo password upfront and make sure it is not asked for again
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# Set keyboard layout
sudo localectl set-keymap --no-convert us
sudo localectl set-x11-keymap --no-convert de pc105 us compose:rwin

# Enable parallel downloads in pacman
sudo sed -i '/^#ParallelDownloads/s/^#//' /etc/pacman.conf

# Enable multi-threading in makepkg and set it to use all available cores
sudo sed -i "/^MAKEFLAGS=/cMAKEFLAGS=\"-j$(nproc)\"" /etc/makepkg.conf

# Enable the multilib repository
sudo sed -i '/\[multilib\]/,/Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Enable the paccache timer for cleaning up the pacman cache weekly
sudo systemctl enable --now paccache.timer

# Update the system
sudo pacman --noconfirm -Syu

# Install yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg --noconfirm -si

# Install all the packages
./install_packages.sh

# Docker
sudo systemctl enable --now docker
sudo usermod -a -G docker $USER

# reditus
rbenv install 3.1.4
rbenv global 3.1.4
rbenv rehash
eval "$(rbenv init - zsh)"

# Rust
rustup default stable
rustup component add rust-analyzer

# Syncthing
systemctl --user enable --now syncthing

# Theming
# Catppuccin TTY
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/s/"$/ vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166 vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173 vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"/' /etc/default/grub
# Catppuccin GRUB
sudo cp -r /usr/share/grub/themes/catppuccin-mocha /boot/grub/themes/
sudo sed -i '/#GRUB_THEME/aGRUB_THEME="/boot/grub/themes/catppuccin-mocha/theme.txt"' /etc/default/grub
# Catppuccin Plymouth
sudo sed -i '/^HOOKS=(/s/base/base plymouth/' /etc/mkinitcpio.conf
sudo sed -i '/^#\[Daemon\]/s/^#//' /etc/plymouth/plymouthd.conf
sudo sed -i '/^#Theme=/cTheme=catppuccin-mocha' /etc/plymouth/plymouthd.conf
# Catppuccin Papirus folders
papirus-folders --color cat-mocha-lavender

# Update the GRUB configuration and the initramfs
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Bat
bat cache --build

# Automatic unlocking of GNOME keyring
awk '
{
    if ($1 == "auth") auth_line=NR;
    if ($1 == "session") session_line=NR;
    file[NR]=$0
}
END {
    for (i=1; i<=NR; i++) {
        if (i == auth_line) print file[i] "\nauth       optional     pam_gnome_keyring.so";
        else if (i == session_line) print file[i] "\nsession    optional     pam_gnome_keyring.so auto_start";
        else print file[i];
    }
}' /etc/pam.d/login >/tmp/temp_file && sudo mv /tmp/temp_file /etc/pam.d/login

# Citrix Workspace
cat <<EOF | sudo tee /usr/bin/pulseaudio >/dev/null
#!/bin/sh

# https://wiki.archlinux.org/title/Citrix#Pipewire
if [ "$1" == "--version" ]; then
    pactl info | grep Server\ Name | sed -e "s/Server Name: //"
else
    echo "This is a dummy file for apps that check if pulseaudio is available by checking for the binary existing"
fi
EOF
sudo chmod +x /usr/bin/pulseaudio
sudo ln -s /usr/lib/libunwind.so /usr/lib/libunwind.so.1
mkdir -p $HOME/.ICAClient/cache
cp /opt/Citrix/ICAClient/config/{All_Regions,Trusted_Region,Unknown_Region,canonicalization,regions}.ini $HOME/.ICAClient/
echo "Set the webcam in ~/.ICAClient/wfclient.ini in the [WFClient] section: HDXWebCamDevice=/dev/video0"

# Run the host-specific post-install script if it exists
post_install_host="20_post-install.$(hostname).sh"
if [[ -f "$post_install_host" ]]; then
    . "$post_install_host"
fi

# Dotfiles
git clone --recurse-submodules https://github.com/drjole/dotfiles ~/.dotfiles
cd ~/.dotfiles
# Create directories so that stow does not create symlinks to the top level directories
find . -mindepth 1 -maxdepth 1 -type d -not -name .git -printf "%f\n" | xargs -I {} mkdir -p "$HOME"/{}
stow .

echo "Now reboot the system"
