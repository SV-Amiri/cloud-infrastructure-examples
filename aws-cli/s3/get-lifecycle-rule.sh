#!/bin/zsh

aws s3api get-bucket-lifecycle-configuration  \
  --bucket my-important-bucket
