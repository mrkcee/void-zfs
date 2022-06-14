#!/bin/fish

check_if_root

echo "Installing extra packages..."
set -l packages \
papirus-icon-theme \
papirus-folders \
font-firacode \
noto-fonts-cjk \
noto-fonts-emoji \
freefont-ttf \
fonts-roboto-ttf \
libreoffice-writer \
libreoffice-calc \
libreoffice-gnome \
vlc \
ghex \
u2f-hidraw-policy \
keepassxc \
nextcloud-client \
neofetch \
htop

install_packages $packages

print_success "Extra packages installed successfully."
