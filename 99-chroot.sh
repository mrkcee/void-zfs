#!/bin/bash

# Import zpool
print 'Import zpool'
zpool import -d /dev/disk/by-id -R /mnt zroot -N -f

# Mount pools and datasets
SYSTEM_DATASET_NAME='void'
zfs mount zroot/ROOT/"$SYSTEM_DATASET_NAME"
zfs mount -a

# Set DISK
print 'Select EFI disk'
select ENTRY in $(ls /dev/disk/by-id/);
do
    DISK="/dev/disk/by-id/$ENTRY"
    echo "$ENTRY selected."
    break
done

EFI="$DISK-part1"
mount "$EFI" /mnt/efi

# Init chroot
print 'Init chroot'
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

chroot /mnt /bin/bash
