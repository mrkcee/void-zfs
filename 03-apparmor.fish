#!/bin/fish

check_if_root

echo "Starting apprarmor installation..."
install_packages "apparmor"

echo "Adding apparmor to kernel commandline..."
zfs set org.zfsbootmenu:commandline="ro quiet nowatchdog loglevel=4 apparmor=1 security=apparmor" zroot/ROOT/void

print_success "Apparmor installation and configuration complete."
