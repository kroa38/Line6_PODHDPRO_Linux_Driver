#!/bin/bash
# Place this file in /usr/src
# change mod to +x

GREEN="\e[32m"
YELLOW="\e[33m"
RED="${RED}"
ENDCOLOR="\e[0m"

echo -e "${GREEN}Building Line6 Pod HD drivers for Linux 6.12${ENDCOLOR}"

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${ENDCOLOR}"
  exit 1
fi

# get linux kernel version
KERNEL_VERSION=$(uname -r | cut -d. -f1,2)
echo -e "${YELLOW}Linux kernel version: $KERNEL_VERSION${ENDCOLOR}"
# get kernel release
KERNEL_RELEASE=$(uname -r)
echo -e "${YELLOW}Linux kernel release: $KERNEL_RELEASE${ENDCOLOR}"
# set linux source dir
LINUX_SOURCE_DIR="/usr/src/linux-source-$KERNEL_VERSION"

# check if linux sources are installed
if [ ! -d "$LINUX_SOURCE_DIR" ]; then
  echo -e "${RED}Linux sources for $KERNEL_VERSION not found. Please install them first.${ENDCOLOR}"
  echo "Would you like to install them now? (y/n)"
  read -r answer
  if [ "$answer" = "y" ]; then
    sudo apt-get install linux-source-$KERNEL_VERSION
    echo -e "${GREEN}Linux sources for $KERNEL_VERSION installed.${ENDCOLOR}"
    echo -e "${YELLOW}Extracting linux sources...${ENDCOLOR}"
    cd /usr/src
    sudo tar -xf linux-source-$KERNEL_VERSION.tar.xz
    cd linux-source-$KERNEL_VERSION
    echo -e "${GREEN}Linux sources for $KERNEL_VERSION extracted.${ENDCOLOR}"
    echo -e "${RED}Copy the files source modified for the line6 drivers in /sound/usb/line6.${ENDCOLOR}"
    exit 0
  else
    echo -e "${RED}Please install linux sources for $KERNEL_VERSION and run this script again.${ENDCOLOR}"
    exit 1
  fi
else
  echo -e "${GREEN}Linux sources for $KERNEL_VERSION found.${ENDCOLOR}"
fi

# Check if kernel headers are installed
if [ ! -d "/usr/src/linux-headers-$KERNEL_RELEASE" ]; then
  echo -e "${RED}Kernel headers for $KERNEL_RELEASE not found.${ENDCOLOR}"
  echo "Would you like to install them now? (y/n)"
  read -r answer
  if [ "$answer" = "y" ]; then
    sudo apt-get install linux-headers-$KERNEL_RELEASE
  else
    echo -e "${RED}Please install kernel headers for $KERNEL_RELEASE and run this script again.${ENDCOLOR}"
    exit 1 
  fi
else
  echo -e "${GREEN}Kernel headers for $KERNEL_RELEASE found.${ENDCOLOR}"
fi

echo -e "${YELLOW}Copying config file from /boot/config-$KERNEL_RELEASE to $LINUX_SOURCE_DIR/.config${ENDCOLOR}"
cd $LINUX_SOURCE_DIR
cp /boot/config-$KERNEL_RELEASE .config

# Build the module
echo -e "${YELLOW}Building the module...${ENDCOLOR}"
make oldconfig
make modules_prepare
cd sound/usb/line6/
rm *.o 2>/dev/null
make -C /lib/modules/$KERNEL_RELEASE/build M=$(pwd) modules

# get a lit of users
echo -e "${YELLOW}Current users logged in:${ENDCOLOR}"
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
echo -e "${YELLOW}Copying the built modules to /home/$username/line6${ENDCOLOR}"
 cp snd-usb-line6.ko "/home/$username/line6"
 cp snd-usb-podhd.ko "/home/$username/line6"
echo -e "${YELLOW}Removing old modules and inserting new ones${ENDCOLOR}"
sudo /usr/sbin/rmmod snd-usb-podhd 2>/dev/null
sudo /usr/sbin/rmmod snd-usb-line6 2>/dev/null
echo -e "${YELLOW}Inserting new modules${ENDCOLOR}"
sudo /usr/sbin/insmod "/home/$username/line6/snd-usb-line6.ko"
sudo /usr/sbin/insmod "/home/$username/line6/snd-usb-podhd.ko"
