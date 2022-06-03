#!/bin/bash

# Select installation disk
print 'Select the disk you installed on:'
select ENTRY in $(ls /dev/disk/by-id/);
do
    DISK="/dev/disk/by-id/$ENTRY"
    echo "Creating boot entries on $ENTRY."
    break
done

# Create UEFI entries
print 'Create efi boot entries'
modprobe efivarfs
mountpoint -q /sys/firmware/efi/efivars \
    || mount -t efivarfs efivarfs /sys/firmware/efi/efivars

if ! efibootmgr | grep ZFSBootMenu
then
    efibootmgr --disk "$DISK" \
      --part 1 \
      --create \
      --label "ZFSBootMenu Backup" \
      --loader "\EFI\ZBM\vmlinuz-backup.efi" \
      --verbose
    efibootmgr --disk "$DISK" \
      --part 1 \
      --create \
      --label "ZFSBootMenu" \
      --loader "\EFI\ZBM\vmlinuz.efi" \
      --verbose
else
    print 'Boot entries already created'
fi
