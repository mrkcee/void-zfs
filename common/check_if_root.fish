#!/bin/fish

function check_if_root
  if not fish_is_root_user
    print_error "Root access is required to run this script."
    exit 1
  end
end

