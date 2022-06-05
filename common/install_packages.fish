#!/bin/fish

function install_packages
  echo 'Installing packages...'
  if not xbps-install -S -y $argv
    print_error "Error occurred while installing packages."
    exit 1
  end
end

