#!/usr/bin/env bash
DESTINATION_DIR=$(dirname $PT_filename)

function raise_error {
  cat << ERROR_MESSAGE
  { "_error": {
    "msg": "Task exited 1:\n $1",
    "kind": "deploy_pe/write_to_file-error",
    "details": { "exitcode": 1 }
    }
  }
ERROR_MESSAGE
  exit 1
}

function output {
  cat << OUTPUT_MESSAGE
  { 
    "file": "$1",
    "msg": "$2"
  }
OUTPUT_MESSAGE
  exit 0
}

function write_file {
  cat <<< "$PT_contents" > "$PT_filename"
  return $?
}

if [ ! -d "$DESTINATION_DIR" ]; then
  mkdir -p $DESTINATION_DIR
fi

if [ -d "$DESTINATION_DIR" ]; then
  if write_file ; then
    output "$PT_filename" "file written successfully"
  else
    raise_error "Write failed; exiting"
  fi

else
  raise_error "Destination directory does not exist and could not be created; exiting"
fi