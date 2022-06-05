#!/bin/fish

check_if_root

echo "Installing and configuring GNOME..."
set -l packages \
xorg-minimal \
nvidia \
gnome \
gdm

install_packages $packages

ln -s /etc/sv/gdm /var/service

print_success "GNOME installation is successfull."

