# Installation Guide

The installation scripts are not idempotent and therefore produce different results if executed multiple times.

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
station wlan0 connect <SSID>
exit
```

## _Optional_: Enable SSH Access to the Live Environment

Enable the sshd service and set a password for the root user:

```shell
systemctl start sshd
passwd root
```

Connect to the machine using SSH from another machine. Use `ip addr` to get the IP address of the machine.

Continue the rest of this guide using SSH from your other machine and run the commands over SSH.
Don't forget to reconnect after a reboot.

## Partition the Disks

Use `lsblk` to identify your disks.

After reading the [Arch Wiki page](https://wiki.archlinux.org/title/Partitioning), decide on a partition layout and apply it using `gdisk`.

These are my partition layouts:

### jolepc

#### `/dev/nvme0n1` (Root and Home Partition)

| Partition | First Sector | Last Sector | `gdisk` Code | Comment            |
| --------- | ------------ | ----------- | ------------ | ------------------ |
| 1         | default      | +512M       | EF00         | EFI (/boot)        |
| 2         | default      | default     | 8309         | / (LUKS encrypted) |

#### `/dev/sda` (General Purpose SDD)

| Partition | First Sector | Last Sector | `gdisk` Code | Comment        |
| --------- | ------------ | ----------- | ------------ | -------------- |
| 1         | default      | default     | 8300         | Arbitrary Data |

#### `/dev/sdb` (General Purpose HDD)

| Partition | First Sector | Last Sector | `gdisk` Code | Comment        |
| --------- | ------------ | ----------- | ------------ | -------------- |
| 1         | default      | default     | 8300         | Arbitrary Data |

### laurinlaptop

#### `/dev/nvme0n1` (Root and Home Partition)

| Partition | First Sector | Last Sector | `gdisk` Code | Comment            |
| --------- | ------------ | ----------- | ------------ | ------------------ |
| 1         | default      | +512M       | EF00         | EFI (/boot)        |
| 2         | default      | default     | 8309         | / (LUKS encrypted) |

## Obtain the installation scripts

The easiest way to obtain the scripts is by installing Git in the live environment and cloning this repository:

```shell
pacman-key --init
pacman -Sy git
git clone https://github.com/LaurinKerkloh/arch
cd arch
```

## Install the Base System

Adjust the values in `00_config.sh`.

Then run the install script:

```shell
./10-install.sh
```

After this script has finished executing, reboot:

```shell
reboot
```

Select the newly installed system in GRUB, log in using your defined credentials.

If GRUB is not shown, refer to [this article](https://wiki.archlinux.org/title/GRUB/EFI_examples#MSI) for help.

Again, obtain the install scripts (when using wifi: use nmcli to connect to wifi again):

```shell
git clone https://github.com/LaurinKerkloh/arch
cd arch
```

The values in `00_config.sh` can be left unchanged as they are not needed for the post-install scripts.

**Only run scripts as your newly created user from now on! The scripts might ask you for the sudo password.**

Execute the post-install script:

```shell
./20-post-install.sh
```

Log out of the system:

```shell
exit
```

## Additional Steps

- Add previous SSH keys.
  - Make sure to `chmod 600` the private key.
- Change origin of dotfiles repository to use SSH.
- Setup catppuccin in Firefox using [this](https://github.com/catppuccin/firefox). I use the lavender flavor.
- Setup catppuccin in Dark Reader using [this](https://github.com/catppuccin/dark-reader).
- Configure [Thunar Volume Managaer](https://wiki.archlinux.org/title/Thunar#Thunar_Volume_Manager)
