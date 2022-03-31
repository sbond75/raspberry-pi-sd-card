#!/bin/bash
# Run this script using sudo. We don't use sudo in this script because we don't want it to prompt for the password midway through since operations take a while in this script.
# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -e # stop on non-zero exit code
set -x # verbose
if [ "$#" -lt 2 ]; then
	echo "Not enough arguments given. Need filename to restore from and a device like /dev/sdb. Exiting."
	exit 1
fi
fname="$1" # Filename to restore from
name="$fname"
device="$2" # Something like /dev/sdb -- restore will be done to this device
size="$3" # Size to restore. Optional (will use the size of $fname given if not provided)
if [ -z "$size" ]; then
	size=$(find "$fname" -printf "%s")
fi

partition_number=2 # Partition number of the ext4 partition on the SD card. Get from `sudo fdisk -l "$device"`

output="img_restored_${name}_on_$(date "+%Y-%m-%d_%H_%M_%S_%Z")"
# Restore
read -p "go?" asd
ddrescue --force --ask -v --size=$size "$fname" "$device" "$output.restore.mapfile.txt"
sleep 5 # Ensure we don't get "This disk is currently in use" from sfdisk
# Resize partition table: resize last partition to max size
echo ", +" | sfdisk -N "$partition_number" "$device" --backup "$device" --backup-file "$name"_beforeRestore_partitionTable_backup
# Expand filesystem to fill
sleep 5 # Without this, it says nothing to do or whatever..
resize2fs -p "$device$partition_number"
read -p "done. press enter to power off the SD card for safe removal." asd
udisksctl power-off -b "$device"
