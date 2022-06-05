#!/bin/fish

check_if_root

echo "Installing nvidia drivers..."
set -l packages \
nvidia \
nvidia-libs-32bit

install_packages $packages

print_success "Nvidia drivers installed successfully."
