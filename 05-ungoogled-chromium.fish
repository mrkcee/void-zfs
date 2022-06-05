#!/bin/fish

echo "Starting installation of ungoogled-chromium for Void..."
echo "Downloading ungoogled-chromium from github..."
set -l github_url "https://github.com/DAINRA/ungoogled-chromium-void/releases/latest"

if not set -l http_get_response $(curl -Is $github_url | grep "location: https")
  print_error "Error when getting latest version."
  false
end

# Get latest version from location value in the response header
set -l latest_version $(echo $http_get_response | string split -r -m1 / | sed "s/v//g")
set -l latest_version $(echo $latest_version[2] | string trim)

# Get redirect url from initial download url
set -l download_url "https://github.com/DAINRA/ungoogled-chromium-void/releases/download/v$latest_version/ungoogled-chromium-$latest_version.x86_64.xbps"
set -l http_get_response $(curl -Is $download_url | grep "location: https:" | sed "s/location: //g")
set -l download_url $(echo $http_get_response | string trim)

set -l download_dir ~/Downloads
mkdir -p $download_dir
if not curl -L -o $download_dir/ungoogled-chromium-$latest_version.x86_64.xbps $download_url
  print_error "Error when downloading xbps package."
  exit 1
end

print_success "Ungoogled-chromium downloaded to $download_dir successfully." 
