#!/bin/fish

check_if_root

echo "Adding SG mirror to xbps..."
mkdir -p /etc/xbps.d
echo "\
repository=https://void.webconverger.org/current
repository=https://void.webconverger.org/current/nonfree
repository=https://void.webconverger.org/current/multilib
repository=https://void.webconverger.org/current/multilib/nonfree
" > /etc/xbps.d/00-repository-main.conf

if not xbps-install -S
  print_error "Error refresing package list."
  exit 1
end

print_success "Added SG mirror successfully."
