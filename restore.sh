#!/bin/bash
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
sudo ddrescue --force --ask -v --size=$size "$fname" "$device" "$output.restore.mapfile.txt"
# Resize partition table: resize last partition to max size
echo ", +" | sudo sfdisk -N "$partition_number" "$device" --backup "$device" --backup-file "$name"_beforeRestore_partitionTable_backup
# Expand filesystem to fill
sleep 5 # Without this, it says nothing to do or whatever..
sudo resize2fs -p "$device$partition_number"
read -p "done. press enter to power off the SD card for safe removal." asd
udisksctl power-off -b "$device"
