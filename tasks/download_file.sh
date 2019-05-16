#!/bin/bash
# shellcheck disable=SC2154

declare PT__installdir
source "$PT__installdir/deploy_pe/files/common.sh"

(( $EUID == 0 )) || fail "This utility must be run as root"

_tmp_dir="$(mktemp -d)"
cd "$_tmp_dir"

# Use the filename in the url as the output file
curl -sfO "$url" || fail "Error downloading PE tarball: $url"

f=(*)
success "{ \"pe_tarball\": \"${PWD}/${f}\" }"
