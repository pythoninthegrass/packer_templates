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

timestamp "Downloading CrowdStrike RPM..."
echo

export CROWDSTRIKE_S3_BUCKET="${CROWDSTRIKE_S3_BUCKET:-}"  # XXX: Edit with a default custom for your environment
export CROWDSTRIKE_S3_BUCKET_DIR="${CROWDSTRIKE_S3_BUCKET_DIR:-crowdstrike}"

if [ -z "${CROWDSTRIKE_S3_BUCKET:-}" ]; then
    timestamp "CROWDSTRIKE_S3_BUCKET environment variable is not set to the name of the bucket where the CROWDSTRIKE_FALCON_SENSOR_RPM has been downloaded to"
    timestamp "Aborting..."
    exit 1
fi

CROWDSTRIKE_FALCON_SENSOR_VERSION="${1:-${CROWDSTRIKE_FALCON_SENSOR_VERSION:-7.17.0-17005}}"

CROWDSTRIKE_FALCON_SENSOR_RPM="${CROWDSTRIKE_FALCON_SENSOR_RPM:-falcon-sensor-$CROWDSTRIKE_FALCON_SENSOR_VERSION.AmazonLinux-2.rpm}"

CROWDSTRIKE_FALCON_SENSOR_RPM_s3_url="$CROWDSTRIKE_S3_BUCKET/$CROWDSTRIKE_BUCKET_DIR/$CROWDSTRIKE_FALCON_SENSOR_RPM"

if ! [ -f "$CROWDSTRIKE_FALCON_SENSOR_RPM" ]; then
    timestamp "RPM not found locally: $CROWDSTRIKE_FALCON_SENSOR_RPM"
    timestamp "Attempting to fetch from S3 Bucket"
    # download the RPM from portal and copy it here
fi

timestamp "Downloading CrowdStrike Falcon Sensor RPM from S3 bucket: $CROWDSTRIKE_FALCON_SENSOR_RPM_s3_url"
echo
aws s3 cp "$CROWDSTRIKE_FALCON_SENSOR_RPM_s3_url" .
echo
