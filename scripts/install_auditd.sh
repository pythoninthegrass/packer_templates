#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-03 01:16:52 +0700 (Mon, 03 Feb 2025)
#
#  https///github.com/HariSekhon/Packer
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

timestamp "Installing Auditd"
echo
# shellcheck disable=SC2154
rpm -q audit ||
$sudo yum install audit
echo
$sudo chkconfig auditd on ||
$sudo systemctl enable auditd
echo
$sudo service auditd start ||
$sudo systemctl start auditd
