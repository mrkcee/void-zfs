#!/bin/fish

set -l nvml_url "https://raw.githubusercontent.com/flightlessmango/MangoHud/master/include/nvml.h"
set -l void_pkg_path ~/development/void-packages

echo "Checking if nvml.h is in the include folder..."
set -l nvml_path $void_pkg_path/masterdir/usr/include/nvml.h
if not test -e $nvml_path
  echo 'Downloading nvml.h...'
  if not curl -L -o $nvml_path https://raw.githubusercontent.com/flightlessmango/MangoHud/master/include/nvml.h
    print_error "Error downloading nvml.h."
    exit 1
  end
end

set -l mangohud_template $void_pkg_path/srcpkgs/MangoHud/template
set -l mangohud_template_temp  $mangohud_template"_new"

echo "Checking MangoHud template file in void-packages..."
if not test -e $mangohud_template
  print_error "MangoHud template / void-packages not found."
  exit 1
end

echo "Applying changes to template..."
sed 's/-Dwith_nvml=disabled/-Dwith_nvml=enabled/g' $mangohud_template > $mangohud_template_temp
cp $mangohud_template_temp $mangohud_template
rm $mangohud_template_temp

echo "Configuring MangoHud..."
echo "\
cpu_stats=1
cpu_temp=1
gpu_stats=1
gpu_temp=1
vram=1
fps=1
frame_timing=0
" > ~/.config/MangoHud/MangoHud.conf

print_success "NVML-enabled MangoHud xbps package can now be built."

