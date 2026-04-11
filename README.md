# Installation Guide

## Obtain the Arch ISO

Download the Arch Linux ISO using the instructions from the [download page](https://archlinux.org/download/).
Also download `b2sums.txt`, `sha256sums.txt`, and the `*.sig` file containing a GPG signature of the image.

[Example download location](https://mirror.netcologne.de/archlinux/iso/latest/) by NetCologne.

## Verify the Integrity of the Arch ISO

```shell
b2sum -c b2sums.txt --ignore-missing
sha256sum -c sha256sums.txt --ignore-missing
gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org
gpg --verify archlinux-x86_64.iso.sig
```

## Prepare the Installation MEDIUM

Define

```shell
INSTALLATION_MEDIUM=/dev/sdc
```

and run

```shell
sudo dd if=archlinux-x86_64.iso of="$INSTALLATION_MEDIUM" bs=4M status="progress"
```

In your BIOS settings, make sure to disable secure boot.

Now boot the Arch ISO Live Environment using the installation medium.

## Connect to the Internet

Either plug in an Ethernet cable or connect to a WLAN using `iwctl` and by executing these commands in the interactive session:

```shell
device list
station wlan0 scan
station wlan0 connect <SSID>
exit
```

## Install Arch Linux

Use the `archinstall` command to install Arch. Make sure to select/set the following installation options:

- Mirrors and repositories: Germany
- Disk configuration: Use the default partitioning layout for your main disk
- Disk > File system: Choose btrfs with a default subvolume layout and compression enabled
- Disk > Disk encryption: Enable LUKS encryption, set a password and select the main partition to enable the encryption of it
- Hostname: Set a hostname
- Authentication > Root password: Set a password
- Authentication > User account: Add your user and make sure to make it a super user
- Network configuration: Choose to copy from ISO
- Timezone: Europe/Berlin

Now start the installation with the configured options.
After the installation is done, reboot the system.

## Run the installation scripts

Inside the newly booted system, run these commands to obtain the installation scripts:

```shell
sudo pacman -S git neovim
git clone https://github.com/drjole/arch.git
```

Change into the cloned directory and adjust the values in `config.sh` as needed:

```shell
cd arch
# Edit `config.sh`...
```

If you want to run additional host-specific configuration, add a `$(hostname).sh` script.
It will be executed at the end of the installation script.

Also, if you want to add host-specific dotfiles, add a `$(hostname)` directory in your dotfiles repository.
It will be stowed when dotfiles are being installed.

Finally, run the installation script.
You will be asked for your password for `sudo` three times: Once at the beginning of the installation and then twice again when `yay` is being installed.

```shell
./install.sh
```

# Additional Notes

- When asked for the initial GNOME keyring password, leave it empty in order for the keyring to be unlocked automatically on login.
- In Firefox, set `intl.regional_prefs.use_os_locales` to `true` in `about:config` in order to use german date formats in Firefox while keeping language at English.
- Add previous SSH keys.
- Make sure to `chmod 600` the private key.
