#!/bin/fish

check_if_root

echo "Starting nftables installation..."

install_packages "nftables"

# TODO: put rules here

print_success "Nftables installation complete."
