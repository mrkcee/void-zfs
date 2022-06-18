#!/bin/fish

check_if_root

echo 'Installing bspwm and related packages...'
set -l packages \
bspwm \
dunst \
alacritty \
rofi \
feh \
elogind \
gnome-keyring \
xprop \
xorg-minimal \
xsetroot \
picom

if not install_packages $packages
  print_error "Error when installing packages."
  exit 1
end

echo 'Exiting sudo...'
exit

echo 'Cloning config files...'
set -l random_guid $(uuidgen)
mkdir -p /tmp/$random_guid
cd /tmp/$random_guid
git clone --depth 1 https://github.com/mrkcee/bspwm-dotfiles.git
./install.fish
rm -rf /tmp/$random_guid

echo 'Updating .xinitrc...'
set -l xinitrc_path ~/.xinitrc
echo "\
pipewire &
pipewire-pulse &
exec bspwm
" > $xinitrc_path

echo 'Updating config.fish...'
echo "\
if status is-interactive
    # Commands to run in interactive sessions can go here
    if test -z $DISPLAY && test $(tty) = '/dev/tty1'
        startx
    end
end
if test -z '$DESKTOP_SESSION'
    for env_var in (gnome-keyring-daemon --start)
        set -l temp_var (echo $env_var | string split '=')
        if test $temp_var[1]='SSH_AUTH_SOCK'
             set -x (echo $env_var | string split '=')
        end
    end
end
" > ~/.config/fish/config.fish

echo 'Setting git helper...'
git config --global credential.helper /usr/libexec/git-core/git-credential-libsecret

print_success "bspwm has been installed and configured successfully."
echo "\
NOTE:
Add the following in /etc/pam.d/login
=========================================================================
Add after the last auth line:
auth            optional        pam_gnome_keyring.so

Add after last session line:
session         optional        pam_gnome_keyring.so auto_start
=========================================================================
"
