#!/bin/fish

# Umount all partitions
echo 'Unmount partitions used during chroot...'
umount /mnt/efi
umount -l /mnt/{dev,proc,sys}
zfs umount -a

# Export zpool
echo 'Exporting zpool...'
zpool export zroot

print_success "Unmounting successful."
