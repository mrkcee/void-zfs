#!/bin/fish

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

print_success "MangoHud installed and configured successfully."
