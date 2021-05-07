#!/bin/bash
declare PT__installdir
source "$PT__installdir/deploy_pe/files/common.sh"
PUPPET_BIN=/opt/puppetlabs/bin

"${PUPPET_BIN}/puppet" infrastructure provision compiler ${compiler}
