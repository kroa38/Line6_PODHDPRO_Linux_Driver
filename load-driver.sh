#!/bin/bash
# this script load driver 
# this script use a dedicated directory but you can change it
# see also script podhd.sh

echo 'load driver for line6'
/usr/sbin/insmod /home/dell/line6/snd-usb-line6.ko
echo 'load driver for PodHD Pro X'
/usr/sbin/insmod /home/dell/line6/snd-usb-podhd.ko

