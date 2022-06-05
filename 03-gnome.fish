#!/bin/fish

check_if_root

echo "Checking for installed nvidia drivers..."
if not xbps-query nvidia
  print_error "NVIDIA package not installed."
  exit 1
end

echo "Installing and configuring GNOME..."
set -l packages \
xorg-minimal \
gnome \
gdm

install_packages $packages

echo "Enabling elogin and GDM service..."
ln -s /etc/sv/elogind /var/service
ln -s /etc/sv/gdm /var/service

print_success "GNOME installation is successfull."

