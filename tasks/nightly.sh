#!/bin/bash
# shellcheck disable=SC2154,SC1090,SC2128

declare PT__installdir
source "$PT__installdir/deploy_pe/files/common.sh"

latest=$(curl "${url}"/"${release}"/ci-ready/LATEST)

success "{ \"latest\": \"${latest}\" }"
