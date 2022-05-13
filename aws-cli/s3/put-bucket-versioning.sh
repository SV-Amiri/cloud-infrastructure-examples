aws s3api put-bucket-versioning \
  --bucket $Bucket \
  --versioning-configuration MFADelete=Disabled,Status=Enabled
