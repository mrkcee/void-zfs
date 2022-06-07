#!/bin/fish

check_if_root

# Select disk
if not set -l selected_disk $(cat /tmp/selected_installation_disk)
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
    echo $selected_disk > /tmp/selected_installation_disk
  else
    print_error "Invalid option. Exiting..."
    exit 1
  end
end

print_info "Selected disk:" $selected_disk
set -l selected_disk "/dev/disk/by-id/"$selected_disk
set -l efi_disk "$selected_disk-part1"

# Root dataset
set -l root_dataset $(cat /tmp/root_dataset)

# Set mirror and architecture
set -l preferred_repo "https://void.webconverger.org/current"
set -l xbps_arch "x86_64"

# Copy keys
echo  'Copying XBPS keys'
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

### Install base system and additional packages
echo 'Installing Void Linux - base system...'
set -gx XBPS_ARCH $xbps_arch
if not xbps-install -y -S -r /mnt -R $preferred_repo base-system
  print_error "Error occurred while installing base system packages. Exiting..."
  exit 1
end
echo "Base-system installed."

echo 'Installing packages...'
set -l packages \
zfs \
zfsbootmenu \
efibootmgr \
gummiboot \
chrony \
snooze \
acpid \
socklog-void \
NetworkManager \
openresolv \
git \
vim \
fish-shell \
curl

if not xbps-install -y -S -r /mnt -R $preferred_repo $packages
  print_error "Error occurred while installing additional packages. Exiting..."
  exit 1
end
echo "Additional packages installed."

# Disable gummiboot post install hooks, only installs for generate-zbm
echo "GUMMIBOOT_DISABLE=1" > /mnt/etc/default/gummiboot

# Init chroot
echo 'Pre-chroot initialization...'
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

# Set hostname
echo 'Setting hostname...'
read -l -p "echo 'Enter hostname: '" hostname
echo $hostname > /mnt/etc/hostname

# Configure zfs
echo 'Copying ZFS files to /mnt...'
cp /etc/hostid /mnt/etc/hostid
cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
# add cp key file here if pool is encrypted

# Configure DNS (from live)
echo 'Copying resolv.conf to /mnt...'
cp /etc/resolv.conf /mnt/etc/

# Prepare locales and keymap
echo 'Setting up locales and keymap in /mnt...'
echo 'KEYMAP=us' > /mnt/etc/vconsole.conf
echo 'en_US.UTF-8 UTF-8' > /mnt/etc/default/libc-locales
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf

# Configure system
echo 'Configuring rc.conf in /mnt...'
echo "\
KEYMAP=\"us\"
TIMEZONE=\"Asia/Manila\"
" >> /mnt/etc/rc.conf

# Configure dracut
echo 'Configuring dracut in /mnt...'
echo "\
hostonly=\"yes\"
nofsck=\"yes\"
add_dracutmodules+=\" zfs \"
omit_dracutmodules+=\" btrfs resume \"
" > /mnt/etc/dracut.conf.d/zol.conf

### Configure username
echo 'Setting username...'
read -l -p "echo 'Enter username: '" user

### Chroot
echo 'Performing chroot to /mnt to configure service...'
echo "\
  # Configure DNS
  resolvconf -u
  # Configure services
  ln -s /etc/sv/chronyd /etc/runit/runsvdir/default/
  ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
  ln -s /etc/sv/acpid /etc/runit/runsvdir/default/
  ln -s /etc/sv/socklog-unix /etc/runit/runsvdir/default/
  ln -s /etc/sv/nanoklogd /etc/runit/runsvdir/default/
  ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/
  # Generates locales
  xbps-reconfigure -f glibc-locales
  # Add user
  useradd -m $user -G network,wheel,socklog,video,audio,input
  # Configure fstab
  grep efi /proc/mounts > /etc/fstab
" | chroot /mnt/ /bin/bash -e

### Configure fstab
echo 'Configuring fstab in /mnt...'
echo "\
$efi_disk /efi vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,errors=remount-ro 0 0
efivarfs  /sys/firmware/efi/efivars  efivarfs  rw,nosuid,nodev,noexec,relatime 0 0
tmpfs     /dev/shm                   tmpfs     rw,nosuid,nodev,noexec,inode64  0 0
tmpfs     /tmp                       tmpfs     defaults,nosuid,nodev           0 0
" >> /mnt/etc/fstab

# Set root passwd
echo 'Setting root password...'
chroot /mnt /bin/passwd

# Set user passwd
printf 'Setting %s password...\n' $user
chroot /mnt /bin/passwd $user

# Configuring sudo
echo 'Configuring sudo in /mnt...'
echo "\
root ALL=(ALL) ALL
$user ALL=(ALL) ALL
Defaults rootpw
" > /mnt/etc/sudoers

### Configure ZFSBootMenu
# Create dirs
mkdir -p /mnt/efi/EFI/ZBM /etc/zfsbootmenu/dracut.conf.d

# Generate ZFSBootMenu efi
echo 'Configuring ZFSBootMenu...'
echo "\
Global:
  ManageImages: true
  BootMountPoint: /efi
  DracutConfDir: /etc/zfsbootmenu/dracut.conf.d
Components:
  Enabled: false
EFI:
  ImageDir: /efi/EFI/ZBM
  Versions: false
  Enabled: true
Kernel:
  CommandLine: ro quiet loglevel=0 zbm.import_policy=hostid
  Prefix: vmlinuz
" > /mnt/etc/zfsbootmenu/config.yaml

# Set cmdline
zfs set org.zfsbootmenu:commandline="ro quiet nowatchdog loglevel=4" zroot/ROOT/"$root_dataset"

echo 'Generating ZFSBootMenu...'
echo '  # Export locale
  export LANG="en_US.UTF-8"
  # Generate initramfs, zfsbootmenu
  xbps-reconfigure -fa
' | chroot /mnt/ /bin/bash -e

echo "Checking boot EFI entries..."
modprobe efivarfs
if not mountpoint -q /sys/firmware/efi/efivars || mount -t efivarfs efivarfs /sys/firmware/efi/efivars
  print_error "EFI is not available."
  exit 1
end

if ! efibootmgr | grep ZFSBootMenu
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

# Umount all partitions
echo 'Unmount partitions used during chroot...'
umount /mnt/efi
umount -l /mnt/{dev,proc,sys}
zfs umount -a

# Export zpool
echo 'Exporting zpool...'
zpool export zroot

print_success "Installation complete."
