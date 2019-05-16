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

lockfile="$("${PUPPET_BIN}/puppet" config print agent_catalog_run_lockfile)"
retries=5
wait_time=300

# Sleep in increments of 1 until either the lockfile is gone or we reach $wait_time
while [[ -e $lockfile ]] && (( wait_time > 0 )); do
  (( wait_time-- ))
  sleep 1
done

# Fail if the lock still exists
[[ -e $lockfile ]] && fail "Agent lockfile $lockfile still exists after waiting $wait_time seconds"

# Run Puppet until there are no changes, otherwise fail
for ((i = 0; i < retries; i++)); do
  "${PUPPET_BIN}/puppet" agent -t --detailed-exitcodes >/dev/null && {
    success '{ "status": "Successfully installed" }'
  }
done

fail "Failed to run Puppet in $retries attempts"
