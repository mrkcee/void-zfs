#!/bin/fish

check_if_root

echo 'Importing zpool...'
zpool import -d /dev/disk/by-id -R /mnt zroot -N -f

echo 'Mounting datasets...'
set -l rootfs_dataset "void"
zfs mount zroot/ROOT/$rootfs_dataset
zfs mount -a

echo "List of available disks:"
set -l all_disks $(find /dev/disk/by-id/ -type l ! -iwholename "*-part*" ! -iwholename "*wwn*" -printf "%f\n")

set -l disk_count $(count $all_disks)
for i in (seq 1 $disk_count)
  # color, index, color, disk, color
  printf '%s(%s) %s %s %s\n' (set_color -o white) $i (set_color -o cyan) $all_disks[$i] (set_color normal)
end

read -l -p 'echo "Select the disk you installed on: "' selected_option
if test "$selected_option" = ""
  print_error "Invalid option. Exiting..."
  exit 1
else if test $selected_option -ge 1 && test $selected_option -le $disk_count
  set selected_disk $all_disks[$selected_option]
else
  print_error "Invalid option. Exiting..."
  exit 1
end

print_info "Selected disk:" $selected_disk
set -l selected_disk "/dev/disk/by-id/"$selected_disk
set -l efi_partition $selected_disk"-part1"

echo 'Mounting EFI partition...'
mount $efi_partition /mnt/efi

echo 'Pre-chroot initialization'
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

echo 'Executing chroot command...'
chroot /mnt /bin/bash
