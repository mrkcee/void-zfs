#!/bin/fish

check_if_root

########## 1a. Select DISK to use ##########
echo "List of available disks:"
set -l all_disks $(find /dev/disk/by-id/ -type l ! -iwholename "*-part*" ! -iwholename "*wwn*" -printf "%f\n")

set -l disk_count $(count $all_disks)
for i in (seq 1 $disk_count)
  # color, index, color, disk, color
  printf '%s(%s) %s %s %s\n' (set_color -o white) $i (set_color -o cyan) $all_disks[$i] (set_color normal)
end

read -l -p 'echo "Select the disk you want to install to: "' selected_option
if test "$selected_option" = ""
  print_error "Invalid option. Exiting..."
  exit 1
else if test $selected_option -ge 1 && test $selected_option -le $disk_count
  set selected_disk $all_disks[$selected_option]
else
  print_error "Invalid option. Exiting..."
  exit 1
end

print_info "Selected disk: " $selected_disk
echo $selected_disk > /tmp/selected_installation_disk
set -l selected_disk "/dev/disk/by-id/"$selected_disk

########## 1b. Clear disk ##########
dd if=/dev/zero of="$selected_disk" bs=512 count=1
wipefs -af "$selected_disk"
sgdisk -Zo "$selected_disk"

########## 2. Create partitions ########## 
# EFI part
echo "Creating EFI partition..."
sgdisk -n1:1M:+512M -t1:EF00 "$selected_disk"
set -l efi_partition $selected_disk"-part1"

# ZFS part
echo "Creating ZFS partition..."
sgdisk -n2:0:0 -t2:bf01 "$selected_disk"

# Inform kernel
partprobe "$selected_disk"

# Format efi part
sleep 1
echo "Formatting EFI partition..."
mkfs.vfat "$efi_partition"

######### 3. Create pool  ##########
# ZFS partition
set -l zfs_partition $selected_disk"-part2"

# Create ZFS pool
echo "Creating ZFS pool..."
zpool create -f -o ashift=12                          \
             -o autotrim=on                           \
             -O acltype=posixacl                      \
             -O compression=on                        \
             -O relatime=on                           \
             -O xattr=sa                              \
             -O normalization=formD                   \
             -O mountpoint=none                       \
             -O canmount=off                          \
             -O devices=off                           \
             -R /mnt                                  \
             zroot "$zfs_partition"

########## 4a. Create dataset - root ##########
# rootfs dataset
echo "Creating root dataset..."
zfs create -o mountpoint=none zroot/ROOT

# Set cmdline
zfs set org.zfsbootmenu:commandline="ro quiet" zroot/ROOT

echo "Creating rootfs dataset..."
set -l rootfs_dataset "void"
echo $rootfs_dataset > /tmp/root_dataset
zfs create -o mountpoint=/ -o canmount=noauto "zroot/ROOT/"$rootfs_dataset

# Generate zfs hostid
echo "Generating hostid..."
zgenhostid

# Set bootfs
echo "Setting ZFS bootfs..."
zpool set bootfs="zroot/ROOT/"$rootfs_dataset zroot

# Manually mount rootfs dataset
echo "Mounting rootfs dataset..."
zfs mount "zroot/ROOT/"$rootfs_dataset

########## 4b. Create dataset - user data ##########
echo "Creating home dataset..."
zfs create -o mountpoint=/ -o canmount=off zroot/USERDATA
zfs create zroot/USERDATA/home

########## 5. Export pool ##########
echo "Exporting pool..."
zpool export zroot

########## 6. Import pool ##########
echo "Importing pool..."
zpool import -d /dev/disk/by-id -R /mnt zroot -N -f

########## 7. Mount system ##########
echo "Mounting rootfs dataset..."
zfs mount "zroot/ROOT/"$rootfs_dataset
zfs mount -a

# Mount EFI part
echo "Mounting EFI partition"
mkdir -p /mnt/efi
mount $efi_partition /mnt/efi

########## 8. Copy zpool cache ##########
echo "Generating and copying zfs cache..."
mkdir -p /mnt/etc/zfs
zpool set cachefile=/etc/zfs/zpool.cache zroot

print_success "Configuration complete."
