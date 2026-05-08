#!/bin/bash
echo 'unload driver'
sudo /usr/sbin/rmmod snd-usb-podhd 2>/dev/null
sudo /usr/sbin/rmmod snd-usb-line6 2>/dev/null
echo 'load driver for line6'
sudo /usr/sbin/insmod /home/dell/line6/snd-usb-line6.ko
echo 'load driver for PodHD Pro X'
sudo /usr/sbin/insmod /home/dell/line6/snd-usb-podhd.ko
