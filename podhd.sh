#!/bin/bash
# Place this file in /usr/src
# change mod to +x
cd /usr/src/
cd linux_6.8.0.orig/
cd linux-6.8/
cp /boot/config-$(uname -r) .config
make oldconfig
make modules_prepare
cd sound/usb/line6/
rm *.o
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
# copy files to a user directory
sudo cp snd-usb-line6.ko /home/dell/line6
sudo cp snd-usb-podhd.ko /home/dell/line6
