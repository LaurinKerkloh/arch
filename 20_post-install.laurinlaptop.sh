#!/bin/bash

set -e

#
# Setup Bluetooth
#
sudo systemctl enable --now bluetooth.service

#
# Backlight control using xorg-xbacklight
#
sudo usermod -aG video "$USER"
sudo cat <<EOF >/etc/udev/rules.d/90-backlight.rules
SUBSYSTEM=="backlight", ACTION=="add", \
  RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

#
# Setup touchpad
#
sudo cat <<EOF >/etc/X11/xorg.conf.d/30-touchpad.conf
Section "InputClass"
    Identifier "devname"
    Driver "libinput"
    Option "ClickMethod" "clickfinger"
    Option "NaturalScrolling" "true"
    Option "Tapping" "on"
EndSection
EOF
