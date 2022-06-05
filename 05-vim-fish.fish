#!/bin/fish

echo "Adding fish shell syntax highlighting support to vim..."

echo "Downloading vim-fish-syntax from github..."
set -l vim_plugins_dir "~/.vim/pack/vendor/start"
mkdir -p $vim_plugins_dir
cd $vim_plugins_dir
if not git clone --depth 1 https://github.com/khaveesh/vim-fish-syntax.git
  print_error "Error cloning repository from github."
  exit 1
end

echo "Updating .vimrc..."
echo "\
if &shell =~# 'fish$'
    set shell=sh
endif
syntax enable
filetype plugin indent on
" >> ~/.vimrc

print_success "Added fish shell syntax hightlighting support to vim."

