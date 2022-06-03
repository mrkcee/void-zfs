#!/bin/bash

# Root dataset
root_dataset=$(cat /tmp/root_dataset)

# Set mirror and architecture
REPO=https://void.webconverger.org/current
ARCH=x86_64

# Copy keys
print 'Copy xbps keys'
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

### Install base system
print 'Install Void Linux'
XBPS_ARCH=$ARCH xbps-install -y -S -r /mnt -R "$REPO" \
  base-system

# Init chroot
print 'Init chroot'
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

# Disable gummiboot post install hooks, only installs for generate-zbm
echo "GUMMIBOOT_DISABLE=1" > /mnt/etc/default/gummiboot

# Install packages
print 'Install packages'
packages=(
  zfs
  zfsbootmenu
  efibootmgr
  gummiboot # required by zfsbootmenu
  chrony # ntp
  snooze # cron
  acpid # power management
  socklog-void # syslog daemon
  NetworkManager
  openresolv
  git
  vim
  fish-shell
  )

XBPS_ARCH=$ARCH xbps-install -y -S -r /mnt -R "$REPO" "${packages[@]}"

# Set hostname
read -r -p 'Please enter hostname : ' hostname
echo "$hostname" > /mnt/etc/hostname

# Configure zfs
print 'Copy ZFS files'
cp /etc/hostid /mnt/etc/hostid
cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
#cp /etc/zfs/zroot.key /mnt/etc/zfs

# Configure DNS (from live)
cp /etc/resolv.conf /mnt/etc/

# Prepare locales and keymap
print 'Prepare locales and keymap'
echo 'KEYMAP=us' > /mnt/etc/vconsole.conf
echo 'en_US.UTF-8 UTF-8' > /mnt/etc/default/libc-locales
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf

# Configure system
cat >> /mnt/etc/rc.conf << EOF
KEYMAP="us"
TIMEZONE="Asia/Manila"
EOF

# Configure dracut
print 'Configure dracut'
cat > /mnt/etc/dracut.conf.d/zol.conf <<"EOF"
hostonly="yes"
nofsck="yes"
add_dracutmodules+=" zfs "
omit_dracutmodules+=" btrfs resume "
EOF

### Configure username
print 'Set your username'
read -r -p "Username: " user

### Chroot
print 'Chroot to configure services'
chroot /mnt/ /bin/bash -e <<EOF
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
EOF

# Configure fstab
print 'Configure fstab'
cat >> /mnt/etc/fstab <<"EOF"
tmpfs     /dev/shm                  tmpfs     rw,nosuid,nodev,noexec,inode64  0 0
tmpfs     /tmp                      tmpfs     defaults,nosuid,nodev           0 0
efivarfs  /sys/firmware/efi/efivars efivarfs  defaults                        0 0
EOF

# Set root passwd
print 'Set root password'
chroot /mnt /bin/passwd

# Set user passwd
print 'Set user password'
chroot /mnt /bin/passwd "$user"

# Configure sudo
print 'Configure sudo'
cat > /mnt/etc/sudoers <<EOF
root ALL=(ALL) ALL
$user ALL=(ALL) ALL
Defaults rootpw
EOF

## Configure zfsbootmenu

# Create dirs
mkdir -p /mnt/efi/EFI/ZBM /etc/zfsbootmenu/dracut.conf.d

# Generate zfsbootmenu efi
print 'Configure zfsbootmenu'
cat > /mnt/etc/zfsbootmenu/config.yaml <<EOF
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
EOF

# Set cmdline
zfs set org.zfsbootmenu:commandline="ro quiet nowatchdog loglevel=4" zroot/ROOT/"$root_dataset"

# Generate ZBM
print 'Generate ZFSBootMenu'
chroot /mnt/ /bin/bash -e <<"EOF"
  # Export locale
  export LANG="en_US.UTF-8"
  # Generate initramfs, zfsbootmenu
  xbps-reconfigure -fa
EOF

# Set DISK
if [[ -f /tmp/disk ]]
then
  DISK=$(cat /tmp/disk)
else
  print 'Select the disk you installed on:'
  select ENTRY in $(ls /dev/disk/by-id/);
  do
      DISK="/dev/disk/by-id/$ENTRY"
      echo "Creating boot entries on $ENTRY."
      break
  done
fi

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

# Umount all parts
print 'Umount all parts'
umount /mnt/efi
umount -l /mnt/{dev,proc,sys}
zfs umount -a

# Export zpool
print 'Export zpool'
zpool export zroot

print "Installation complete."
