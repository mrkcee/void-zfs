#!/bin/fish

check_if_root

set -l packages \
pulseaudio-utils \
pipewire

install_packages $packages

print_success "Pipewire has been installed and configured successfully."
echo "Note: Configure pipewire to autostart when your desktop manager loads."
