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

timestamp "CrowdStrike Install script starting..."
echo

CROWDSTRIKE_FALCON_SENSOR_VERSION="${1:-${CROWDSTRIKE_FALCON_SENSOR_VERSION:-7.17.0-17005}}"

# used to fetch secret from AWS Secrets Manager if CROWDSTRIKE_FALCON_SENSOR_SECRET environment variable is not set in the local environment
CROWDSTRIKE_AWS_SECRETS_MANAGER_SECRET="${CROWDSTRIKE_AWS_SECRETS_MANAGER_SECRET:-crowdstrike}"

crowdstrike_falcon_sensor_secret="${CROWDSTRIKE_FALCON_SENSOR_SECRET:-}"

CROWDSTRIKE_FALCON_SENSOR_RPM="${CROWDSTRIKE_FALCON_SENSOR_RPM:-/tmp/packer/falcon-sensor-$CROWDSTRIKE_FALCON_SENSOR_VERSION.AmazonLinux-2.rpm}"

timestamp "Installing CrowdStrike Falcon Sensor RPM: $CROWDSTRIKE_FALCON_SENSOR_RPM"
echo
# shellcheck disable=SC2154
$sudo yum install -y "$CROWDSTRIKE_FALCON_SENSOR_RPM"
echo

if [ -z "$crowdstrike_falcon_sensor_secret" ]; then
    timestamp "CROWDSTRIKE_FALCON_SENSOR_SECRET not set in environment, will attempt to fetch it from AWS Secrets Manager"
    echo
    if [ -n "${CROWDSTRIKE_AWS_SECRETS_MANAGER_SECRET:-}" ]; then
        timestamp "Fetching CrowdStrike Falcon Sensor secret from AWS Secrets Manager: $CROWDSTRIKE_AWS_SECRETS_MANAGER_SECRET"
        echo
        crowdstrike_falcon_sensor_secret="$(
            aws secretsmanager get-secret-value --secret-id "$CROWDSTRIKE_AWS_SECRETS_MANAGER_SECRET" |
            jq -r '.SecretString // ""'
        )"
        if [ -z "$crowdstrike_falcon_sensor_secret" ]; then
            timestamp "ERROR: failed to find CROWDSTRIKE_FALCON_SENSOR_SECRET in AWS Secrets Manager secret '$CROWDSTRIKE_FALCON_SENSOR_SECRET'"
            exit 1
        fi
    else
        timestamp "ERROR: CROWDSTRIKE_FALCON_SENSOR_SECRET environment variable is not set"
        timestamp "and there is no CROWDSTRIKE_AWS_SECRETS_MANAGER_SECRET set to pull from either, exiting..." >&2
        exit 1
    fi
fi
echo

if [ "${crowdstrike_falcon_sensor_secret:0:1}" = "{" ]; then
    if ! type -P jq &>/dev/null; then
        timestamp "Installing jq to parse AWS Secrets Manager secret"
        echo
        $sudo yum install -y jq
        echo
    fi
    crowdstrike_falcon_sensor_secret="$(jq -r '.CID' <<< "$crowdstrike_falcon_sensor_secret")"
fi

timestamp "Configuring CrowdStrike with Falcon Sensor secret..."
$sudo /opt/CrowdStrike/falconctl -s -f --cid="$crowdstrike_falcon_sensor_secret"
echo
timestamp "Starting Falcon Sensor..."
echo
$sudo service falcon-sensor start
echo
timestamp "Falcon Sensor version:"
echo
$sudo /opt/CrowdStrike/falconctl -g --version
