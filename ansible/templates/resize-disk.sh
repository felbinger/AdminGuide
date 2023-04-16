#!/bin/bash

# script to resize root lv to maximum storage
# only appliable to debian 11 servers using lvm

echo '!!! Create a snapshot of this system before executing this script !!!'
read -p "Do you really want to resize the root partition to the maximum size (y/N): " run_confirmation

if [[ ${run_confirmation} != "Y" ]] && [[ ${run_confirmation} != "y" ]]; then
    echo "Exiting..."
    exit 0
fi

vg_name=$(vgs --noheadings -o vg_name | tr -d " ")

# see https://linuxhandbook.com/resize-lvm-partition/
(
    echo "d"          # delete partition
    echo "2"

    echo "n"          # new partition
    echo "e"          # extended partition
    echo "2"

    echo ""           # first sector
    echo ""           # last sector

    echo "n"          # new logical partition (others shouldn't be possible)
    echo ""           # first sector
    echo ""           # last sector
    echo "N"          # do not remove partition signatur

    echo "t"          # change partition type of partition 5 to linux lvm
    echo "5"
    echo "8e"

    echo "w"          # write changes
) | fdisk /dev/sda

# resize physical volume
pvresize /dev/sda5

# resize logical volume
lvextend -l +100%FREE /dev/${vg_name}/root

# resize ext4 partition
resize2fs /dev/${vg_name}/root

read -p "A reboot is highly suggested to check if the resize was successful and the system is still bootable " reboot_confirmation
if [[ ${reboot_confirmation} == "Y" ]] || [[ ${reboot_confirmation} == "y" ]]; then
    reboot
fi

