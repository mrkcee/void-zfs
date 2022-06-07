#!/bin/fish

set -l dev_path ~/development

mkdir -p $dev_path
cd $dev_path

if not test -e $dev_path/void-packages/xbps-src
  echo "Cloning void-packages..."
  if not git clone --depth 1 https://github.com/void-linux/void-packages.git
    print_error "Error when cloning void-packages."
    exit 1
  end
end

cd void-packages

echo "Setting preferred mirror..."
echo "\
repository=https://void.webconverger.org/current
repository=https://void.webconverger.org/current/nonfree
repository=https://void.webconverger.org/current/multilib
repository=https://void.webconverger.org/current/debug
" > etc/xbps.d/repos-remote.conf

echo "Installing binary-bootstrap..."
./xbps-src binary-bootstrap

print_success "void-packages has been cloned and configured successully."

