#!/bin/fish

set -l user_function_dir "~/.config/fish/functions"

printf 'Copy common functions to %s...\n' $user_function_dir
mkdir -p $user_function_dir
cp common/*.fish $user_function_dir

