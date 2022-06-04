#!/bin/fish

########## FUNCTIONS
function print_error
  set_color -o red; echo $argv
  set_color normal
end

function print_success
  set_color -o green; echo $argv
  set_color normal
end

function print_info
  set_color -o blue; echo $argv
  set_color normal
end

########## MAIN START
echo "List of available disks:"
set -l all_disks $(ls -1 /dev/disk/by-id)

set -l disk_count $(count $all_disks)
for i in (seq 1 $disk_count)
  # color, index, color, disk
  printf '(%s%s) %s %s %s\n' (set_color -o white) $i (set_color -o cyan) $all_disks[$i] (set_color normal)
end

read -l -p 'echo "Select the disk you installed on: "' selected_option
if test "$selected_option" = ""
  print_error "Invalid option. Exiting..."
  return 0
else if test $selected_option -ge 1 && test $selected_option -le $disk_count
  set selected_disk $all_disks[$selected_option]
else
  print_error "Invalid option. Exiting..."
  return 0
end

print_info "Selected disk:" $selected_disk

echo "Checking boot EFI entries..."
modprobe efivarfs
mountpoint -q /sys/firmware/efi/efivars \
    || mount -t efivarfs efivarfs /sys/firmware/efi/efivars

if ! efibootmgr | grep ZFSBootMenu
  echo "ZFSBootMenu not found."
  echo "Creating boot entries..."
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
  print_success "ZBM boot entries creation completed successfully."
else
  print_success "Boot entries are already existing."
end
