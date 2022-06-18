#!/bin/fish

check_if_root

echo "Starting apprarmor installation..."
install_packages "apparmor"

echo "Adding apparmor to kernel commandline..."
set -l current_commandline $(zfs get -H -o value org.zfsbootmenu:commandline zroot/ROOT/void)
set -l new_commandline "$current_commandline apparmor=1 security=apparmor"
zfs set org.zfsbootmenu:commandline="$new_commandline" zroot/ROOT/void

print_success "Apparmor installation and configuration complete."
