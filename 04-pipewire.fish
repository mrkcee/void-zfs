#!/bin/fish

check_if_root

set -l packages \
pulseaudio-utils \
pipewire

install_packages $packages

## Disable autospawn in pulseaudio
echo "autospawn= no " >> /etc/pulse/client.conf

## Create pipewire script in /opt
set -l pipewire_script /opt/pipewire/pipewire.sh
mkdir -p /opt/pipewire
echo "\
#!/bin/sh
pipewire &
pipewire-pulse &
" > $pipewire_script

chmod +x $pipewire_script

## Create desktop shortcut
echo "\
[Desktop Entry]
Name=Pipewire
Type=Application
Terminal=false
Comment=Autostart Pipewire
Exec=/opt/pipewire/pipewire.sh
" > /usr/share/applications/pipewire.desktop

print_success "Pipewire has been installed and configured successfully."
echo "Note: Configure pipewire to autostart when your desktop manager loads."
