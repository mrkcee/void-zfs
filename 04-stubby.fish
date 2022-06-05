#!/bin/fish

check_if_root

set -l packages \
stubby \
dnsmasq

install_packages $packages

echo "Configuring stubby..."
echo "\
listen_addresses:
  - 127.0.0.1@53000
  - 0::1@53000
" >> /etc/stubby/stubby.yml

echo "Configuring dnsmasq..."
echo "\
no-resolv
proxy-dnssec
server=::1#53000
server=127.0.0.1#53000
listen-address=::1,127.0.0.1
" > /etc/dnsmasq.conf

echo "\
nameserver 127.0.0.1
nameserver ::1
" > /etc/resolv.conf

chattr +i /etc/resolv.conf

print_success "DNS configuration is complete."
echo "Note: update stubby.yml with your desired DNS service provider configuration."
