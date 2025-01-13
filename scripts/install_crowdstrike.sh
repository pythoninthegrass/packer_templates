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

# borrowed from https://github.com/HariSekhon/DevOps-Bash-tools/blob/master/lib/utils.sh
timestamp(){
    printf "%s  %s\n" "$(date '+%F %T')" "$*" >&2
}

timestamp "CrowdStrike Install script starting..."
echo

date
echo

uname -a
echo

sudo=""
if [ "$EUID" -ne 0 ]; then
    timestamp "Not running as root, prefixing 'sudo' to commands that need root privileges"
    echo
    sudo=sudo
fi

# In case you have to pull the Falcon Sensor secret from AWS Secrets Manager
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-eu-west-1}"
export AWS_REGION="$AWS_DEFAULT_REGION"

CLOUDSTRIKE_FALCON_SENSOR_VERSION="${CLOUDSTRIKE_FALCON_SENSOR_VERSION:-7.17.0-17005}"

# used to fetch secret from AWS Secrets Manager if CLOUDSTRIKE_FALCON_SENSOR_SECRET environment variable is not set in the local environment
CLOUDSTRIKE_AWS_SECRETS_MANAGER_SECRET="${CLOUDSTRIKE_AWS_SECRETS_MANAGER_SECRET:-crowdstrike}"

cloudstrike_falcon_sensor_secret="${CLOUDSTRIKE_FALCON_SENSOR_SECRET:-}"

cloudstrike_falcon_sensor_rpm="falcon-sensor-$CLOUDSTRIKE_FALCON_SENSOR_VERSION.AmazonLinux-2.rpm"

cloudstrike_falcon_sensor_rpm_s3_url="$S3_BUCKET/${CROWDSTRIKE_BUCKET_DIR:-cloudstrike}/$cloudstrike_falcon_sensor_rpm"

if ! [ -f "$cloudstrike_falcon_sensor_rpm" ]; then
    timestamp "RPM not found locally: $cloudstrike_falcon_sensor_rpm"
    timestamp "Attempting to fetch from S3 Bucket"
    # download the RPM from portal and copy it here
    if [ -z "${S3_INSTALLABLES_BUCKET:-}" ]; then
        timestamp "S3_INSTALLABLES_BUCKET environment variable is not set to the name of the bucket where the falcon-sensor-<version>.AmazonLinux-2.rpm has been downloaded to"
        timestamp "Aborting..."
        exit 1
    fi
fi

timestamp "Downloading CloudStrike Falcon Sensor RPM from S3 bucket: $cloudstrike_falcon_sensor_rpm_s3_url"
echo
aws s3 cp "$cloudstrike_falcon_sensor_rpm_s3_url" .
echo

timestamp "Installing CloudStrike Falcon Sensor RPM: $cloudstrike_falcon_sensor_rpm"
echo
$sudo yum install -y "$cloudstrike_falcon_sensor_rpm"
echo

if [ -z "$cloudstrike_falcon_sensor_secret" ]; then
    timestamp "CLOUDSTRIKE_FALCON_SENSOR_SECRET not set in environment, will attempt to fetch it from AWS Secrets Manager"
    echo
    if [ -n "${CLOUDSTRIKE_AWS_SECRETS_MANAGER_SECRET:-}" ]; then
        if ! type -P jq &>/dev/null; then
            timestamp "Installing jq to parse AWS Secrets Manager secret"
            echo
            $sudo yum install -y jq
            echo
        fi
        timestamp "Fetching CloudStrike Falcon Sensor secret from AWS Secrets Manager: $CLOUDSTRIKE_AWS_SECRETS_MANAGER_SECRET"
        echo
        cloudstrike_falcon_sensor_secret="$(
            aws secretsmanager get-secret-value --secret-id "$CLOUDSTRIKE_AWS_SECRETS_MANAGER_SECRET" |
            jq -r '.SecretString // ""'
        )"
        if [ -z "$cloudstrike_falcon_sensor_secret" ]; then
            timestamp "ERROR: failed to find CLOUDSTRIKE_FALCON_SENSOR_SECRET in AWS Secrets Manager secret '$CLOUDSTRIKE_FALCON_SENSOR_SECRET'"
            exit 1
        fi
    else
        timestamp "ERROR: CLOUDSTRIKE_FALCON_SENSOR_SECRET environment variable is not set"
        timestamp "and there is no CLOUDSTRIKE_AWS_SECRETS_MANAGER_SECRET set to pull from either, exiting..." >&2
        exit 1
    fi
fi
echo

timestamp "Configuring CrowdStrike with Falcon Sensor secret..."
$sudo /opt/CrowdStrike/falconctl -s -f --cid="$cloudstrike_falcon_sensor_secret"
echo
timestamp "Starting Falcon Sensor..."
echo
$sudo service falcon-sensor start
echo
timestamp "Falcon Sensor version:"
echo
#$sudo /opt/CrowdStrike/falconctl -g --version
/opt/CrowdStrike/falconctl -g --version
