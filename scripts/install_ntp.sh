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

timestamp "Installing Cronyd / Ntpd"
echo

# shellcheck disable=SC2154
rpm -q chrony ||
$sudo yum install chrony ||
rpm -q ntpd ||
$sudo yum install ntpd

echo

$sudo chkconfig chronyd on ||
$sudo systemctl enable chronyd ||
$sudo chkconfig ntpd on ||
$sudo systemctl enable ntpd

echo

$sudo service chronyd start ||
$sudo systemctl start chronyd ||
$sudo service ntpd start ||
$sudo systemctl start ntpd
