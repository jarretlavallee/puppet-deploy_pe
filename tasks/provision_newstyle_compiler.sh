#!/bin/bash
declare PT__installdir
source "$PT__installdir/deploy_pe/files/common.sh"
PUPPET_BIN=/opt/puppetlabs/bin
/bin/mkdir -p /root/.puppetlabs
/bin/curl -X POST -H 'Content-Type: application/json' --cacert $(${PUPPET_BIN}/puppet config print cacert) https://$(${PUPPET_BIN}/puppet config print server):4433/rbac-api/v1/auth/token -d '{"login":"admin","password":"puppetlabs","lifetime":"0"}' | /bin/python -c 'import sys, json; print json.load(sys.stdin)["token"]' > ~/.puppetlabs/token
"${PUPPET_BIN}/puppet" infrastructure provision compiler ${compiler}
