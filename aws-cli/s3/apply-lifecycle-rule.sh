#!/bin/zsh

aws s3api put-bucket-lifecycle-configuration  \
  --bucket mindhive-misc-backup-files \
  --lifecycle-configuration file://./lifecycle-rule-s3-prod.json
