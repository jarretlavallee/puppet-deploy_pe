#!/bin/bash
# shellcheck disable=SC2154,SC2034,SC1090

declare PT__installdir
source "$PT__installdir/deploy_pe/files/common.sh"
PUPPET_BIN=/opt/puppetlabs/bin

(( EUID == 0 )) || fail "This utility must be run as root"

# Hackish, but cd to the directory we get via the PT_tarball parameter
# Extract it, cd to the directory with the .tar.gz suffix, and run the installer
cd "${tarball%/*}" || fail
tar xf "$tarball" || fail "Error extracting PE tarball"
cd "${tarball%.tar.gz*}" || fail
chmod +x ./puppet-enterprise-installer

./puppet-enterprise-installer -y -c "$pe_conf" || fail "Error installing PE"

success "PE installed"
