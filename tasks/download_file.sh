#!/bin/bash
# shellcheck disable=SC2154,SC1090,SC2128

declare PT__installdir
source "$PT__installdir/deploy_pe/files/common.sh"

(( EUID == 0 )) || fail "This utility must be run as root"

_tmp_dir="$(mktemp -d)"
cd "$_tmp_dir" || fail

# Use the filename in the url as the output file
curl -sLfO "$url" || fail "Error downloading PE tarball: $url"

# We intentionally only want the first element of ${f}
f=(*)
success "{ \"output_file\": \"${PWD}/${f}\" }"
