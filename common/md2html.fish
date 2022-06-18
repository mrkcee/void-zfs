#!/bin/fish

set usage_message " 
md2html 
Fish script wrapper to convert a markdown file to a HTML file 

Usage:
md2html [INPUT FILENAME] [OUTPUT FILENAME]
 
"

function md2html
  if test \( -z "$argv[1]" \) -o \( -z "$argv[2]" \)
    echo $usage_message
    return
  end
  
  set default_path $(pwd)
  set input_path $default_path"/"
  set output_path $default_path"/"
  if echo $argv[1] | grep -q /
    set input_path ""
  end
  if echo $argv[2] | grep -q /
    set output_path ""
  end
  
  if pandoc "$input_path$argv[1]" --to html --from markdown --standalone --pdf-engine=lualatex -o "$output_path$argv[2]"
    print_success "File '$argv[1]' converted to HTML successfully."
  end
end
