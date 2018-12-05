#!/usr/bin/env bash
TARBALL=$PT_tarball
PE_CONF=$PT_pe_conf
TMPDIR=${PT_tmpdir:-$(dirname $PT_tarball)}
PEDIR=$(dirname $(tar -tf "$PT_tarball" | head -n 1))


function raise_error {
  cat << ERROR_MESSAGE
  { "_error": {
    "msg": "Task exited 1:\n $1",
    "kind": "deploy_pe/install_pe-error",
    "details": { "exitcode": 1 }
    }
  }
ERROR_MESSAGE
  exit 1
}

function output {
  cat << OUTPUT_MESSAGE
  { 
    "msg": "$1"
  }
OUTPUT_MESSAGE
  exit 0
}

function validate_input {
  if [ ! -e "$TARBALL" ]; then
    raise_error "Tarball, '$TARBALL', is missing; exiting"
  fi

  if [ ! -e "$PE_CONF" ]; then
    raise_error "pe.conf, '$PE_CONF', is missing; exiting"
  fi

  if [ ! -d "$TMPDIR" ]; then
    mkdir -p $TMPDIR
    if [ ! -d "$TMPDIR" ]; then
      raise_error "Tmpdir, '$TMPDIR', does not exist and could not be created; exiting"
    fi
  fi

}

function execute_command {
    exit_code=${2:-"0"}
    eval $1
    if [ "$?" -ne "$exit_code" ]
    then
        raise_error "Command '$1' failed; exiting"
    fi
}

function extract_tarball {
  # TODO: Ensure tar is installed on the system
  execute_command "tar -xvf $TARBALL -C $TMPDIR"
}

function run_pe_installer {

  execute_command "chmod +x $TMPDIR/$PEDIR/puppet-enterprise-installer"
  execute_command "$TMPDIR/$PEDIR/puppet-enterprise-installer -y -c $PE_CONF"

}

function run_puppet {
  lockfile=$(/opt/puppetlabs/bin/puppet config print agent_catalog_run_lockfile)
  retries=5
  wait_time=300
  exit_code=0
  while [[ -f "$lockfile" && wait_time -gt 0 ]]
  do
    sleep 1
  done

  for run in $(seq 1 $retries); do
    exec 3>&1
    output=$(/opt/puppetlabs/bin/puppet agent -t --detailed-exitcodes | tee /dev/fd/3; exit "${PIPESTATUS[0]}")
    exit_code=$?

    case $exit_code in
    0)
      return 0
    ;;
    *)
    continue
    ;;
    esac
  done

  return $exit_code
}

# Main
validate_input
extract_tarball
run_pe_installer
if run_puppet; then
  output "Sucessfully installed"
else
  raise_error "Failed to run puppet"
fi
