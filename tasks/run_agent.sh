#!/bin/bash
# shellcheck disable=SC2154,SC2034,SC1090,SC2181,SC1091

declare PT__installdir
source "$PT__installdir/deploy_pe/files/common.sh"
PUPPET_BIN=/opt/puppetlabs/bin
retries=${retries:-5}
wait_time=${wait_time:-300}
show_output=${show_output:-true}

(( EUID == 0 )) || fail "This utility must be run as root"

lockfile="$("${PUPPET_BIN}/puppet" config print agent_catalog_run_lockfile)"

# Sleep in increments of 1 until either the lockfile is gone or we reach $wait_time
while [[ -e $lockfile ]] && (( wait_time > 0 )); do
  if [ "$show_output" = true ] && [[ $(( wait_time % 30 )) -eq 0 ]]; then
    echo "Another agent run is in progress. Waiting for the current agent run to complete"
  fi
  (( wait_time-- ))
  sleep 1
done

# Fail if the lock still exists
[[ -e $lockfile ]] && fail "Agent lockfile $lockfile still exists after waiting $wait_time seconds"

# Run Puppet until there are no changes, otherwise fail
for ((i = 0; i < retries; i++)); do
  if [[ "$show_output" = true ]] ; then
    echo "Running the Puppet agent. Attempt ${i} of ${retries}"
    "${PUPPET_BIN}/puppet" agent -t
  else
    "${PUPPET_BIN}/puppet" agent -t > /dev/null
  fi
  if [[ $? -eq 0 ]] ; then
    {
      success '{ "status": "Successfully ran Puppet agent" }'
    }
  fi
done

fail "Failed to run Puppet agent in $retries attempts"
