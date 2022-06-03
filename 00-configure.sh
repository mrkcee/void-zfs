#!/bin/bash

########## 1a. Select DISK to use ##########
select ENTRY in $(ls /dev/disk/by-id/);
do
    DISK="/dev/disk/by-id/$ENTRY"
    echo "$DISK" > /tmp/disk
    echo "Installing on $ENTRY."
    break
done

########## 1b. Clear disk ##########
dd if=/dev/zero of="$DISK" bs=512 count=1
wipefs -af "$DISK"
sgdisk -Zo "$DISK"

########## 2. Create partitions ########## 
# EFI part
print "Creating EFI part"
sgdisk -n1:1M:+512M -t1:EF00 "$DISK"
EFI="$DISK-part1"

# ZFS part
print "Creating ZFS part"
sgdisk -n2:0:0 -t2:bf01 "$DISK"

# Inform kernel
partprobe "$DISK"

# Format efi part
sleep 1
print "Format EFI part"
mkfs.vfat "$EFI"

########## 3. Create pool  ##########
# ZFS part
ZFS="$DISK-part2"

# Create ZFS pool
print "Create ZFS pool"
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
             zroot "$ZFS"


########## 4a. Create dataset - root ##########
# rootfs dataset
print "Create root dataset"
zfs create -o mountpoint=none zroot/ROOT

# Set cmdline
zfs set org.zfsbootmenu:commandline="ro quiet" zroot/ROOT

print "Create rootfs dataset"
SYSTEM_DATASET_NAME="void"
echo "$SYSTEM_DATASET_NAME" > /tmp/root_dataset
zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/"$SYSTEM_DATASET_NAME"

# Generate zfs hostid
print "Generate hostid"
zgenhostid

# Set bootfs
print "Set ZFS bootfs"
zpool set bootfs="zroot/ROOT/$SYSTEM_DATASET_NAME" zroot

# Manually mount slash dataset
zfs mount zroot/ROOT/"$SYSTEM_DATASET_NAME"

########## 4b. Create dataset - user data ##########
print "Create home dataset"
zfs create -o mountpoint=/ -o canmount=off zroot/USERDATA
zfs create zroot/USERDATA/home

########## 5. Export pool ##########
print "Export pool"
zpool export zroot

########## 6. Import pool ##########
print "Import pool"
zpool import -d /dev/disk/by-id -R /mnt zroot -N -f

########## 7. Mount system ##########
print "Mount slash dataset"
zfs mount zroot/ROOT/"$SYSTEM_DATASET_NAME"
zfs mount -a

# Mount EFI part
print "Mount EFI part"
EFI="$DISK-part1"
mkdir -p /mnt/efi
mount "$EFI" /mnt/efi

########## 8. Copy zpool cache ##########
print "Generate and copy zfs cache"
mkdir -p /mnt/etc/zfs
zpool set cachefile=/etc/zfs/zpool.cache zroot

print "Configuration complete."
