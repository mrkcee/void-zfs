#!/bin/fish

check_if_root

echo "Installing and configuring GNOME..."
set -l packages \
xorg-minimal \
nvidia \
gnome \
gdm

install_packages $packages

echo "Enabling elogin and GDM service..."
ln -s /etc/sv/elogind /var/service
ln -s /etc/sv/gdm /var/service

print_success "GNOME installation is successfull."

