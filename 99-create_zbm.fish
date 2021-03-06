#!/bin/fish

check_if_root

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

echo "Checking boot EFI entries..."
modprobe efivarfs
if not mountpoint -q /sys/firmware/efi/efivars || mount -t efivarfs efivarfs /sys/firmware/efi/efivars
  print_error "EFI is not available."
  exit 1
end

if not efibootmgr | grep ZFSBootMenu
  echo "ZFSBootMenu not found."
  echo "Creating boot entries..."
  efibootmgr --disk "$selected_disk" \
    --part 1 \
    --create \
    --label "ZFSBootMenu Backup" \
    --loader "\EFI\ZBM\vmlinuz-backup.efi" \
    --verbose
  efibootmgr --disk "$selected_disk" \
    --part 1 \
    --create \
    --label "ZFSBootMenu" \
    --loader "\EFI\ZBM\vmlinuz.efi" \
    --verbose
  print_success "ZBM boot entries creation completed successfully."
else
  print_success "Boot entries are already existing."
end
