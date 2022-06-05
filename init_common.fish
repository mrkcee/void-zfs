#!/bin/fish

if not fish_is_root_user
  set color red; echo "Root access is required."; set color normal
  exit 1
end

set -l function_dir /etc/fish/functions

printf 'Copying common functions to %s...\n' $function_dir
mkdir -p $function_dir
set -l files_in_dir $(ls ./common)
for file in $files_in_dir
  cp ./common/$file $function_dir
end

set color green; printf "Copied common files to %s successfully.\n" $function_dir; set color normal
