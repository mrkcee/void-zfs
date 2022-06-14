#!/bin/fish

check_if_root

echo 'Installing AwesomeWM and related packages...'
set -l packages \
awesome \
inotify-tools \
alacritty \
rofi \
pcmanfm \
betterlockscreen \
elogind

if not install_packages $packages
  print_error "Error when installing packages."
  exit 1
end

echo 'Creating awm config folder...'
set -l awm_config_folder ~/.config/awesome
mkdir -p $awm_config_folder

echo 'Cloning config files...'

echo 'Updating .xinitrc...'
set -l xinitrc_path ~/.xinitrc
echo "\
pipewire &
pipewire-pulse &
exec dbus-launch --sh-syntax --exit-with-session awesome
" > $xinitrc_path

echo 'Updating config.fish...'
echo "\
if status is-interactive
    # Commands to run in interactive sessions can go here
    if test -z $DISPLAY && test $(tty) = '/dev/tty1'
        startx
    end
end
" > ~/.config/fish/config.fish

print_success "AwesomeWM has been installed and configured successfully."
