#!/bin/bash
# Place this file in /usr/src
# change mod to +x

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
ENDCOLOR="\e[0m"

WORKING_DIR=$(pwd)
SRC_DIR="/usr/src"

echo -e "${GREEN}Building Line6 Pod HD drivers for Linux 6.12${ENDCOLOR}"

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${ENDCOLOR}"
  exit 1
fi

cd $SRC_DIR

# get linux kernel version
KERNEL_VERSION=$(uname -r | cut -d. -f1,2)
echo -e "${GREEN}Linux kernel version: $KERNEL_VERSION${ENDCOLOR}"
# get kernel release
KERNEL_RELEASE=$(uname -r)
echo -e "${GREEN}Linux kernel release: $KERNEL_RELEASE${ENDCOLOR}"
# set linux source dir
LINUX_SOURCE_DIR="$SRC_DIR/linux-source-$KERNEL_VERSION"

# check if linux sources are installed
if [ ! -d "$LINUX_SOURCE_DIR" ]; then
  echo -e "${YELLOW}Linux sources for $KERNEL_VERSION not found. Please install them first.${ENDCOLOR}"
  echo -e "${YELLOW}Would you like to install them now? (y/n)${ENDCOLOR}"
  read -r answer
  if [ "$answer" = "y" ]; then
    sudo apt install linux-source-$KERNEL_VERSION
    echo -e "${GREEN}Linux sources for $KERNEL_VERSION installed.${ENDCOLOR}"
    echo -e "${GREEN}Extracting linux sources...${ENDCOLOR}"
    cd $SRC_DIR
    sudo tar -xf linux-source-$KERNEL_VERSION.tar.xz
    cd linux-source-$KERNEL_VERSION
    echo -e "${GREEN}Linux sources for $KERNEL_VERSION extracted.${ENDCOLOR}"
    echo -e "${GREEN}Copy the files source modified for the line6 drivers in /sound/usb/line6.${ENDCOLOR}"
  else
    echo -e "${RED}Please install linux sources for $KERNEL_VERSION and run this script again.${ENDCOLOR}"
    exit 1
  fi
else
  echo -e "${GREEN}Linux sources for $KERNEL_VERSION already installed.${ENDCOLOR}"
fi

# Check if kernel headers are installed
if [ ! -d "/usr/src/linux-headers-$KERNEL_RELEASE" ]; then
  echo -e "${YELLOW}Kernel headers for kernel $KERNEL_RELEASE not found.${ENDCOLOR}"
  echo -e "${YELLOW}Would you like to install them now? (y/n)${ENDCOLOR}"
  read -r answer
  if [ "$answer" = "y" ]; then
    sudo apt install linux-headers-$KERNEL_RELEASE
  else
    echo -e "${RED}Please install kernel headers for $KERNEL_RELEASE and run this script again.${ENDCOLOR}"
    exit 1 
  fi
else
  echo -e "${GREEN}Kernel headers for $KERNEL_RELEASE already installed.${ENDCOLOR}"
fi

# set line6 driver source dir
LINE6_DIR="$LINUX_SOURCE_DIR/sound/usb/line6"

#test if file podhd.c exists
if [ ! -f "$LINE6_DIR/podhd.c" ]; then
  echo -e "${RED}File podhd.c not found in $LINE6_DIR. Please check your Linux source directory.${ENDCOLOR}"
  exit 1
fi
# Modify the podhd.c file by replacing the string '(0x4156' with '(0x415A'
echo -e "${GREEN}Modifying podhd.c to replace code 0x4156 with 0x415A...${ENDCOLOR}"
sed -i 's/0x4156/0x415A/g' $LINE6_DIR/podhd.c

echo -e "${GREEN}Copying config file from /boot/config-$KERNEL_RELEASE to $LINUX_SOURCE_DIR/.config${ENDCOLOR}"
cd $LINUX_SOURCE_DIR
cp /boot/config-$KERNEL_RELEASE .config

# Build the module
echo -e "${GREEN}Building the module...${ENDCOLOR}"
make oldconfig
make modules_prepare
cd $LINE6_DIR
rm *.o 2>/dev/null
make -C /lib/modules/$KERNEL_RELEASE/build M=$(pwd) modules



# get a lit of users
echo -e "${GREEN}Current users logged in:${ENDCOLOR}"
who | awk '{print $1}' | sort | uniq
echo -e "${YELLOW}Please enter the username of the user who will use the module:${ENDCOLOR}"
read -r username
if id "$username" &>/dev/null; then
  echo -e "${GREEN}User $username found.${ENDCOLOR}"
else
  echo -e "${RED}User $username not found. Please enter a valid username.${ENDCOLOR}"
  exit 1
fi
# Test if dir for user exists
if [ ! -d "/home/$username" ]; then
  echo -e "${RED}Home directory for user $username not found. Please enter a valid username.${ENDCOLOR}"
  exit 1
fi
if [ ! -d "/home/$username/line6" ]; then
  mkdir "/home/$username/line6"
fi
echo -e "${GREEN}Copying the built modules to /home/$username/line6${ENDCOLOR}"
 cp snd-usb-line6.ko "/home/$username/line6"
 cp snd-usb-podhd.ko "/home/$username/line6"
echo -e "${GREEN}Removing old modules and inserting new ones${ENDCOLOR}"
sudo /usr/sbin/rmmod snd-usb-podhd 2>/dev/null
sudo /usr/sbin/rmmod snd-usb-line6 2>/dev/null
echo -e "${GREEN}Inserting new modules${ENDCOLOR}"
sudo /usr/sbin/insmod "/home/$username/line6/snd-usb-line6.ko"
sudo /usr/sbin/insmod "/home/$username/line6/snd-usb-podhd.ko"
