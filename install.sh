#!/bin/bash

set -ex

INSTALLATION_DIRECTORY=$(pwd)

# Load configuration variables
. config.sh

# Locales
if grep -q '^#.*en_US\.UTF-8' /etc/locale.gen>/dev/null 2>&1; then
    sudo sed -i 's/^# *\(en_US\.UTF-8.*\)/\1/' /etc/locale.gen
    sudo locale-gen
fi
if grep -q '^#.*de_DE\.UTF-8' /etc/locale.gen>/dev/null 2>&1; then
    sudo sed -i 's/^# *\(de_DE\.UTF-8.*\)/\1/' /etc/locale.gen
    sudo locale-gen
fi

# Configure pacman
# Enable multilib repository
if ! grep -q "^\[multilib\]" /etc/pacman.conf>/dev/null 2>&1; then
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
fi
# Fancy stuff
if ! grep -q '^Color' /etc/pacman.conf>/dev/null 2>&1; then
    sudo sed -i '/^\[options\]/a Color' /etc/pacman.conf
fi
if ! grep -q '^ILoveCandy' /etc/pacman.conf>/dev/null 2>&1; then
    sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
fi

# Configure makepkg
if grep -q '^MAKEFLAGS=' /etc/makepkg.conf>/dev/null 2>&1; then
    sudo sed -i "s/^MAKEFLAGS=.*/MAKEFLAGS=\"-j\$(nproc)\"/" /etc/makepkg.conf
else
    echo "MAKEFLAGS=\"-j\$(nproc)\"" | sudo tee -a /etc/makepkg.conf
fi

# Update the system
sudo pacman -Syu --noconfirm

# Install all the packages
# Always needed
sudo pacman -S --noconfirm --needed base-devel git
# Graphics
sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
# Audio
sudo pacman -S --noconfirm --needed pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack wireplumber
# Hyprland
sudo pacman -S --noconfirm --needed hyprland uwsm libnewt xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    hyprpolkitagent hypridle hyprpaper waybar rofi dunst hyprlock wl-clipboard hyprsunset grim slurp qt5-wayland qt6-wayland
# Desktop applications
sudo pacman -S --noconfirm --needed alacritty firefox nautilus sushi ffmpegthumbnailer spotify-launcher discord pavucontrol \
    gimp inkscape loupe libreoffice-still nextcloud-client gnome-keyring signal-desktop vlc vlc-plugin-ffmpeg xournalpp steam teamspeak3
# Theming
sudo pacman -S --noconfirm --needed gnome-themes-extra kvantum-qt5 \
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-font-awesome otf-font-awesome
# Terminal applications
sudo pacman -S --noconfirm --needed zathura zathura-pdf-poppler \
    zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting \
    neovim fzf starship eza bat htop tmux man-db ripgrep fd lazygit jq unzip \
    pacman-contrib inetutils

# yay
if ! command -v yay >/dev/null 2>&1; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd "$INSTALLATION_DIRECTORY"
fi

# Dotfiles
sudo pacman -S --noconfirm --needed stow
if [ ! -d "$HOME/.dotfiles" ]; then
    git clone --recurse-submodules "$DOTFILES_URL_HTTPS" "$HOME/.dotfiles"
else
    cd "$HOME/.dotfiles"
    git remote set-url origin "$DOTFILES_URL_HTTPS"
    git pull --recurse-submodules
    cd "$INSTALLATION_DIRECTORY"
fi
cd "$HOME/.dotfiles"
git remote set-url origin "$DOTFILES_URL_SSH"
# Ensure that these directories exist so that stow puts the symlinks inside them instead of using themselves as symlink targets
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share"
mkdir -p "$HOME/.ssh"
stow shared
if [[ -d "$(hostname)" ]]; then
    stow "$(hostname)"
fi
cd "$INSTALLATION_DIRECTORY"
bat cache --build

# Shell
if [ "$SHELL" != "/bin/zsh" ]; then
    sudo chsh --shell /bin/zsh "$USER_NAME"
fi

# Configure dconf to use a text-based file
if ! grep -q "service-db:keyfile/user" /etc/dconf/profile/user>/dev/null 2>&1; then
    sudo mkdir -p /etc/dconf/profile
    echo "service-db:keyfile/user" | sudo tee /etc/dconf/profile/user
fi

# Configure seamless login
. seamless-login.sh

# Don't require network interfaces to be routable for boot
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service

# Don't show boot selection menu
sudo bootctl set-timeout 0

# Docker
sudo pacman -S --noconfirm --needed docker docker-compose docker-buildx
sudo systemctl enable --now docker.service
sudo usermod -a -G docker "$USER_NAME"

# Theming
yay -S --noconfirm --needed --answerdiff N bibata-cursor-theme-bin
yay -S --noconfirm --needed --answerdiff N yaru-icon-theme
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface icon-theme "Yaru-purple-dark"

# Bluetooth
sudo pacman -S --noconfirm --needed blueman bluez bluez-utils
sudo systemctl enable --now bluetooth.service

# Development environments
sudo pacman -S --noconfirm --needed mise
mise trust "$HOME/.dotfiles/shared/.config/mise/config.toml"
mise use -g usage
mise use -g node
mise use -g ruby

# reditus
sudo pacman -S --noconfirm --needed pre-commit mkcert postgresql keepassxc chromium

# Make sure the initramfs is rebuilt at least once after the installation
sudo mkinitcpio -P

# Run host-specific configuration script
if [[ -x "$(hostname).sh" ]]; then
    . "$(hostname).sh"
fi

# Snapper and snap-pac
sudo pacman -S --noconfirm --needed snapper
if ! sudo snapper -c root get-config >/dev/null 2>&1 ; then
    sudo snapper -c root create-config /
fi
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
sudo pacman -S --noconfirm --needed snap-pac


# Done
echo "All done! Now reboot and enjoy."
