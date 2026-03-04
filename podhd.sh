#!/bin/bash
# Place this file in /usr/src
# change mod to +x
cd /usr/src/linux-source-6.12/
cp /boot/config-$(uname -r) .config

# Build
make oldconfig
make modules_prepare
cd sound/usb/line6/
rm *.o
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

# Test if dir line6 exist
if [ ! -d "/home/dell/line6" ]; then
  mkdir /home/dell/line6
fi
 cp snd-usb-line6.ko /home/dell/line6
 cp snd-usb-podhd.ko /home/dell/line6
 rmmod snd-usb-podhd
 rmmod snd-usb-line6
 insmod /home/dell/line6/snd-usb-line6.ko
 insmod /home/dell/line6/snd-usb-podhd.ko
#  depmod -a
#  modprobe snd-usb-podhd
#  modprobe snd-usb-line6