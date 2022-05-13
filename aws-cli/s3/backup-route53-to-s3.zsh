#!/bin/zsh

# ----------------------------------------------------------------------
#
# Purpose: Backup AWS Route 53 zones to a S3 bucket. Modified from
# https://thepracticalsysadmin.com/backup-route-53-zones/
#
# Require "aws" and "jq" command-line utilities.
#
# ----------------------------------------------------------------------

set -emuo pipefail

Backup_Bucket='s3://mindhive-misc-backup-files/Route_53/Zones/'
Cli_Path='/usr/local/bin'
Backup_Dir=$(mktemp -d)

# Trust, but verify.
if [[ ! -d "$Backup_Dir" ]]; then
    >&2 echo "Failed to create temp directory $Backup_Dir"
    exit 1
fi
# Remove temp directory on script exit.
trap "exit 1"           HUP INT PIPE QUIT TERM
trap 'rm -rf "$Backup_Dir"'  EXIT

# Dump all zones to a file and upload to s3
function backup_all_zones () {
  # Enumerate all zones
  declare -a zones
  local IFS=$'\n'
  zones=( $(${Cli_Path}/aws route53 list-hosted-zones | \
    jq -r '.HostedZones[].Id' | \
    sed "s/\/hostedzone\///") )
  for zone in ${zones}
  do
    echo "Backing up zone $zone"
    ${Cli_Path}/aws route53 list-resource-record-sets --hosted-zone-id ${zone} > ${Backup_Dir}/${zone}.json
  done

  # Upload backups to s3
  ${Cli_Path}/aws s3 cp ${Backup_Dir} ${Backup_Bucket} --recursive --sse
}

# Execute
time backup_all_zones
