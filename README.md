# Running PODHD Pro X under linux

Because we love linux !  
Tested on : Ubuntu 22-04 (jammy) 

## 1) Get the righ ID of the PODHD PRO X:

run the command :
```
> sudo dmesg | grep 'idVendor=0e41'
[ 3239.784010] usb 3-1.3.1: New USB device found, idVendor=0e41, idProduct=415a, bcdDevice= 0.00
```
0x0e41  = Line 6 Manufacturer ID  
__0x415a__ = __PODHD Pro X ID__

## 2) Linux kernel source

Get your current kernel version:
```
> uname -r
6.8.0-47-generic
```
Download the most closest version of your kernel:  
For me is 6.8.0 and extract under __/usr/src/__
  
```
> wget https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.8.tar.gz
> tar -xvf linux-6.8.tar.gz
> mv linux-6.8/ /usr/src/.
```

## 3) Make Module Prepare
Remove root permission
```
> cd /usr/src/
> chown -R $(whoami):$(whoami) linux-6.8/
```
Copy your current kernel config inside the source
```
> cd /usr/src/linux-6.8
> cp /boot/config-$(uname -r) .config
```
make module_prepare
```
> cd /usr/src/linux-6.8
> make oldconfig
> make modules_prepare
```

## 4) Modify PODHD. C file

For working you have to simply modify the value of LINE6_PODHDDESKTOP inside the file :  
> linux-6.8.0/sound/usb/line6/podhd.c

> replace __0x4156__ by __0x415a__

```
/* table of devices that work with this driver */
static const struct usb_device_id podhd_id_table[] = {
	/* TODO: no need to alloc data interfaces when only audio is used */
	{ LINE6_DEVICE(0x5057),    .driver_info = LINE6_PODHD300 },
	{ LINE6_DEVICE(0x5058),    .driver_info = LINE6_PODHD400 },
	{ LINE6_IF_NUM(0x414D, 0), .driver_info = LINE6_PODHD500 },
	{ LINE6_IF_NUM(0x414A, 0), .driver_info = LINE6_PODX3 },
	{ LINE6_IF_NUM(0x414B, 0), .driver_info = LINE6_PODX3LIVE },
	{ LINE6_IF_NUM(0x4159, 0), .driver_info = LINE6_PODHD500X },
	{ LINE6_IF_NUM(0x415a, 0), .driver_info = LINE6_PODHDDESKTOP },
	{}
};
```
##  5) Rebuild module

```
> cd linux-6.8/sound/usb/line6
> make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
```
if all is ok you have successfully build the modules for the PODHD Pro X.  
```
> ll *.ko
-rw-r--r-- 1 root root 1567408 Oct 23 15:56 snd-usb-line6.ko
-rw-r--r-- 1 root root  418600 Oct 23 16:22 snd-usb-podhd.ko
-rw-r--r-- 1 root root  417152 Oct 23 15:56 snd-usb-pod.ko
-rw-r--r-- 1 root root  438232 Oct 23 15:56 snd-usb-toneport.ko
-rw-r--r-- 1 root root  384128 Oct 23 15:56 snd-usb-variax.ko
```
##  6) unload old module .

verify if you have line modules loaded
```
> sudo lsmod | grep snd_usb
snd_usb_podhd          16384  0
snd_usb_line6          49152  3 snd_usb_podhd
snd_usb_audio         499712  5
snd_usbmidi_lib        53248  1 snd_usb_audio
snd_hwdep              20480  3 snd_usb_audio,snd_hda_codec,snd_usb_line6
snd_ump                45056  1 snd_usb_audio
snd_rawmidi            57344  4 snd_seq_midi,snd_usbmidi_lib,snd_usb_line6,snd_ump
mc                     81920  1 snd_usb_audio

```
For me __snd_usb_pod_hd__ and __snd_usb_line6__ must be unloaded

```
> sudo rmmod snd_usb_podhd 
> sudo rmmod snd_usb_line6
```
##  7) Insert new module.

Insert first line6 and after podhd
```
> sudo insmod ./snd-usb-line6.ko
> sudo insmod ./snd-usb-podhd.ko
```


## 8) Big thanks to :   
Markus Grabner <grabner@icg.tugraz.at> who is at the origin of this driver.



