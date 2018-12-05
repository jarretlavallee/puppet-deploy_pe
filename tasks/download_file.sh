#!/usr/bin/env bash
URL=$PT_url
DESTINATION=$PT_destination
DESTINATION_DIR=$(dirname $DESTINATION)

function raise_error {
  cat << ERROR_MESSAGE
  { "_error": {
    "msg": "Task exited 1:\n $1",
    "kind": "deploy_pe/download-error",
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

function download_file {
  url_size=$(curl -s -L -f --head "$URL" | sed -n 's/Content-Length: \([0-9]\+\)/\1/p' | tr -d '\012\015')
  local_file_size=$(stat -c%s "$DESTINATION" 2>/dev/null)
  if [[ ! -z "$url_size" && ! -z "$local_file_size" && "$url_size" -eq "$local_file_size" ]]; then
    return 0
  else
    curl -f -L -k -o "$DESTINATION" "$URL"
    return $?
  fi
}

if [ ! -d "$DESTINATION_DIR" ]; then
  mkdir -p $DESTINATION_DIR
fi

if [ -d "$DESTINATION_DIR" ]; then
  if download_file ; then
    output "$DESTINATION" "file downloaded successfully"
  else
    raise_error "Download failed; exiting"
  fi

else
  raise_error "Destination directory does not exist and could not be created; exiting"
fi