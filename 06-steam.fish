#!/bin/fish

check_if_root

echo "Starting steam installation..."
set -l packages \
steam \
libgcc-32bit \
libstdc++-32bit \
libdrm-32bit \
libglvnd-32bit \
nvidia-libs-32bit

install_packages $packages

print_success "Steam installation complete."
