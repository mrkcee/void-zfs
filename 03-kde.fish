#!/bin/fish

check_if_root

echo "Checking for installed nvidia drivers..."
if not xbps-query nvidia
  print_error "NVIDIA package not installed."
  exit 1
end

echo "Installing and configuring KDE..."
set -l packages \
xorg-minimal \
qt5 \
qt5-tools \
kde5 \
kde5-baseapps

install_packages $packages

echo "Enabling elogin and SDDM service..."
ln -s /etc/sv/elogind /var/service
ln -s /etc/sv/sddm /var/service

print_success "KDE installation is successfull."

