#!/bin/bash

# Umount all parts
print 'Umount all parts'
umount /mnt/efi
umount -l /mnt/{dev,proc,sys}
zfs umount -a

# Export zpool
print 'Export zpool'
zpool export zroot
