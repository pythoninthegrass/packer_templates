#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-11 01:43:02 +0700 (Sat, 11 Jan 2025)
#
#  https://github.com/HariSekhon/Packer
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

# shellcheck disable=SC1091
source "/tmp/packer/lib/utils.sh"

timestamp "Yum System Packages Update script starting..."
echo

$sudo yum update -y
echo

timestamp "Yum System Packages updated - make sure to call 'final.sh' script to clean out the yum caches at end of build"
