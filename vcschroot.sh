#!/usr/bin/env bash
#==============================================================================
#   ______ _______ _______  ______  _____       _______ _     _ _____ _______
#  |_____/ |______    |    |_____/ |     |      |_____|  \___/    |   |______
#  |    \_ |______    |    |    \_ |_____|      |     | _/   \_ __|__ ______|
#                                                                           
#==============================================================================
#     Program: vcschroot.sh
#      Author: retroaxis.tv
#         Ver: 20210128
# Description: This script creates a 'chroot' environment of the Atari VCS OS
#              using a Linux Distribution either running live from a USB drive
#              or installed to the M.2 SATA expansion drive slot.
#
# Usage:  vcschroot [command]
#
# Notes:
#   This has only been tested on Ubuntu 20.04.  This is a generic script
#   and should work on all Linux distros. Please report problems.
#
#==============================================================================

### Configuration Variables ###
#
# target location for the chroot starting point
CHROOT_DIR="/mnt/atari"

# Unmount all VCS discs on actions? 1=Yes  0=No
UMOUNT_ALL=1

# Mount host root inside of the chroot at /mnt?  1=Yes 0=No
MOUNT_HOST=1

#
###############################

# BEGIN

# action_hostumount : Unmounts the VCS mountpoints from the host os
action_hostumount(){
    echo "Action: Unmounting VCS volumes (var, rootfs, home) from host"
    # AtariOS /var (var)
    echo "* unmounting (/dev/mmcblk0p4)"
    umount /dev/mmcblk0p4
    # AtariOS / (rootfs)
    echo "* unmounting (/dev/mmcblk0p8)"
    umount /dev/mmcblk0p8
    # AtariOS /home (storage)
    echo "* unmounting (/dev/mmcblk0p9)"
    umount /dev/mmcblk0p9
    # If the umount all flag is set, unmount all VCSos Mounts on the local host.
    if [ $UMOUNT_ALL -eq 1 ]
    then
      echo "* umounting (1,2,3,7)..."
      umount /dev/mmcblk0p1 # efi1
      umount /dev/mmcblk0p2 # efi2
      umount /dev/mmcblk0p3 # efi3
      umount /dev/mmcblk0p7 # rootfs1
    fi
    echo "[DONE]"
}

action_chrootumount(){
    echo "Action: Unmounting VCS volumes (var, rootfs, home, sys, proc, dev) from chroot"
    # BIND MOUNTS
    if [ $MOUNT_HOST -eq 1 ]
    then
      umount $CHROOT_DIR/mnt
    fi
    echo "* unmounting /sys bind"
      umount $CHROOT_DIR/sys
    echo "* unmounting /proc bind"
      umount $CHROOT_DIR/proc
    echo "* unmounting /dev bind"
      umount $CHROOT_DIR/dev
    # AtariOS /var (var)
    echo "* unmounting /var (/dev/mmcblk0p4)"
      umount $CHROOT_DIR/var
    # AtariOS /home (storage)
    echo "* unmounting /home (/dev/mmcblk0p9)"
      umount $CHROOT_DIR/home
    # AtariOS / (rootfs)
    echo "* unmounting / (/dev/mmcblk0p8)"
      umount $CHROOT_DIR
    echo "[DONE]"  
}



# action_makedirs : Create the mountpoints
action_makedir() {
    echo -n "Action: Creating mount points for chroot envrionment..."
    if [ -d $CHROOT_DIR ]
    then
      echo "\n'$CHROOT_DIR' already exists. Try running 'destroy' or 'enter' instead, exiting with error"
      exit 1
    else
      mkdir -p $CHROOT_DIR
    fi
    echo "[DONE]"
}

# action_deldirs : Delete the directories
action_deldir() {
    echo -n "Action: Removing mount points for chroot environments..."
    if [ -d $CHROOT_DIR ]
    then
      rmdir $CHROOT_DIR
    else
      echo "'$CHROOT_DIR' does not exist. nothing to do"
      return 0
    fi
    echo "[DONE]"
}

# action_mountvcs: 
action_mountvcs(){
    echo "Action: Mounting VCS discs..."
    # mount root on part 8
    echo "  root (/dev/mmcblck0p8) =>  $CHROOT_DIR"
      mount /dev/mmcblk0p8 $CHROOT_DIR
    # mount var on part 4
    echo "  var  (/dev/mmcblck0p4) =>  $CHROOT_DIR/var"
      mount /dev/mmcblk0p4 $CHROOT_DIR/var
    # mount home on part 9
    echo "  home (/dev/mmcblck0p9) =>  $CHROOT_DIR/home"
      mount /dev/mmcblk0p9 $CHROOT_DIR/home
    # bind mount /sys
    echo "  sys  (/sys bind mount) =>  $CHROOT_DIR/sys"
      mount -o bind /sys $CHROOT_DIR/sys
    # bind mount /dev
    echo "  dev  (/dev bind mount) =>  $CHROOT_DIR/dev"
      mount -o bind /dev $CHROOT_DIR/dev
    # bind mount /proc
    echo "  sys  (/proc bind mount) =>  $CHROOT_DIR/proc"
      mount -o bind /proc $CHROOT_DIR/proc
    if [ $MOUNT_HOST -eq 1 ]
    then
      mount -o bind / $CHROOT_DIR/mnt
    fi
    echo "[DONE]"
}

# Display a help message
showhelp(){
cat <<HELP
     Program: vcschroot.sh
      Author: retroaxis.tv
         Ver: 20210128
 Description: This script creates a 'chroot' environment of the Atari VCS OS
              using a Linux Distribution either running live from a USB drive
              or installed to the M.2 SATA expansion drive slot.

 Usage:  vcschroot [command]

   Where command is one of the following actions (also used in this order):
  
    setup  :: prepares the chrooted environment
    enter  :: enter the chrooted environment
   remove  :: removes the chrooted environment

HELP

}


enter_chroot(){
    echo -e "Action: Entering the VCS OS in a chrooted environment...\n"
    if [ $MOUNT_HOST -eq 1 ]
    then
        cat <<MSG
Your host filesystem is available and mounted as '/mnt'. To use commands
from your host Linux OS, you can either it manually, for example: 

# /mnt/usr/bin/strace
# /mnt/bin/bash   
           ^^^^ yes, you can run Bash since the VCS only has busybox

or add the environment paths by appending:

export PATH=$PATH:/mnt/bin:/mnt/sbin:/mnt/usr/bin:/mnt/usr/sbin

If you use the export PATH however, you may unknowing call the wrong binary.
Not all comands may work.

MSG
    fi
    echo -e "Type 'exit' to leave.  \n To cleanup 'vcschroot remove'\n\nCheck out RetroAxis.TV & Have a lot of fun!"
    chroot $CHROOT_DIR /bin/dash
    echo -e "\n\nIf you are finished, don't forget to run '$0 remove' to cleanup.\n"
    exit 0
}

# MAIN

echo "--------------------------------------------------------------"
echo " [ vcschroot ] : AtariVCS Environment chroot for Linux        "
echo "                 courtesy of RetroAxis.TV                     "
echo "--------------------------------------------------------------"

if [ -z $1 ]
then
  showhelp
fi

WHOAMI=`whoami`
if [ $WHOAMI != "root" ]
then 
  echo "This command requires root privileges, try again using 'sudo $0 $1"
  exit 1
fi


case "$1" in
  "help" )
    showhelp
  ;;
  "setup" )
    # Create the chroot directory if not exist. Note this will exit if the dir exists as a failsafe
    action_makedir
    # Clear any existing mount points on these in the running Linux OS
    # some Linux Desktops automount drives into /media/$user/$fslabel as an example
    action_hostumount
    # Mount the structure
    action_mountvcs
    echo -e "\n[READY] : Atari VCS chroot prepared at $CHROOT_DIR, run '$0 enter' when ready.\n"
  ;;
  
  "remove" )
    # Unmount everything
    action_chrootumount
    # Remove directories
    action_deldir
  ;;

  "enter")
    enter_chroot
  ;;
esac

exit 0
#EOL