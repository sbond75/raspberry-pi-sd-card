#!/bin/bash
set -e # stop on non-zero exit code
set -x # verbose
name="$1" # Something like "sift1", "fore1", etc.
device="$2" # Something like /dev/sdb
if [ "$#" -lt 2 ]; then
	echo "Not enough arguments given. Need name like sift1 and device like /dev/sdb. Exiting."
	exit 1
fi
partition_number=2 # Partition number of the ext4 partition on the SD card. Get from `sudo fdisk -l "$device"`
sector_size=512 # MUST BE 512 from fdisk
start_sector=532480 # Start sector of the ext4 partition on the SD card
res=$(sudo resize2fs -P "$device$partition_number" | awk '{print $NF}')
echo "$res"
#read asd
size=$(($res*4096/1024/1024+1)) # in MiB
echo "$size"
size_sectors=$(($size*1024*1024/512))
echo "$size_sectors"
end_sector=$(($start_sector + $size_sectors))
echo "$end_sector"
output="img_${name}_$(date "+%Y-%m-%d_%H_%M_%S_%Z")"
# DONETODO: run parted to resize here
read -p "go? (else ctrl-c) " asd
# Back up partition table
#echo 'TYPE "quit" WITHOUT QUOTES IN THIS:'
#sudo sfdisk --backup "$device" --backup-file "$name"_partitionTable_backup
# Check for errors and fix them
set +e
sudo e2fsck -f -y -v -C 0 "$device$partition_number"
resCode="$?"
echo "Exit code: $resCode"
if [ "$resCode" = "0" ] || [ "$resCode" = "1" ]; then
	:
	# Ok (1 means errors corrected)
else
	exit "$resCode"
fi
set -e
# Resize partition's filesystem
sudo resize2fs -p "$device$partition_number" "$size_sectors"s
#sudo parted "$device" resize "$partition_number" "$start_sector"s "$end_sector"s
# Resize partition table entry
sleep 2
echo 'TYPE "write" WITHOUT QUOTES IN THIS:'
echo ", $size"M | sudo sfdisk -N "$partition_number" "$device" --backup "$device" --backup-file "$name"_partitionTable_backup # M=MiB
read -p "go?" asd
# Make disk image
sudo ddrescue --ask -v --size=$(($size_sectors*512)) "$device" "$output" "$output.mapfile.txt"
