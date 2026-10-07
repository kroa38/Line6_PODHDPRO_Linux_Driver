#!/bin/bash
echo 'unload actual driver'
sudo /usr/sbin/rmmod snd-usb-podhd 2>/dev/null
sudo /usr/sbin/rmmod snd-usb-line6 2>/dev/null
echo 'load driver for PodHD Pro X'
sudo /usr/sbin/insmod /home/dell/Line6_PODHDPRO_Linux_Driver/snd-usb-line6.ko
sudo /usr/sbin/insmod /home/dell/Line6_PODHDPRO_Linux_Driver/snd-usb-podhd.ko
