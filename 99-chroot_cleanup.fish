#!/bin/fish

# Umount all partitions
echo 'Unmount partitions used during chroot...'
umount /mnt/efi
umount -l /mnt/{dev,proc,sys}
zfs umount -a

# Export zpool
echo 'Exporting zpool...'
zpool export zroot

set_color green; echo "Unmounting successful."
set_color normal
