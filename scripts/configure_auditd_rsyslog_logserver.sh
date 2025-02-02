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

logserver="${1:-}"  # XXX: Edit to default to your environment syslog server IP

if [ -z "$logserver" ]; then
    die "Logserver address not set and not given as arg"
fi

# Amazon Linux 2
auditd_syslog_conf="/etc/audisp/plugins.d/syslog.conf"

timestamp "Updating $auditd_syslog_conf to enable LOG_LOCAL6"
echo

backup_timestamp="$(date '+%F%H')"
# shellcheck disable=SC2154
$sudo cp -av "$auditd_syslog_conf" "$auditd_syslog_conf.$backup_timestamp"
echo

echo "Before:"
echo

$sudo cat "$auditd_syslog_conf"
echo

$sudo sed -i 's/active = .*/active = yes/' "$auditd_syslog_conf"
$sudo sed -i 's/args = .*/args = LOG_LOCAL6/' "$auditd_syslog_conf"
echo
echo "After:"
echo

$sudo cat "$auditd_syslog_conf"
echo
echo "Diff:"
echo

$sudo diff "$auditd_syslog_conf.$backup_timestamp" "$auditd_syslog_conf"
echo

$sudo service auditd restart ||
$sudo systemctl restart auditd
echo

timestamp "Updating rsyslog.conf to send to logserver: $logserver"
echo
$sudo sh -c "echo 'local6.* @@$logserver' >> /etc/rsyslog.conf"
echo

timestamp "Restarting RSyslog"
echo
$sudo service rsyslog restart ||
$sudo systemctl rsyslog restart rsyslog

$sudo service rsyslog status ||
$sudo systemctl status rsyslog
