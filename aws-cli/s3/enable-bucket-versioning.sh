# Enable bucket versioning on buckets that do not have versioning set

for Bucket in $(aws s3api list-buckets | \
  jq -r '.Buckets[].Name')
do
  aws s3api get-bucket-versioning \
    --bucket ${Bucket} | \
    jq -r .Status | \
    grep "Enabled" > /dev/null
  if [[ $? -ne 0 ]]
  then
    echo "Enabling versioning on bucket ${Bucket}"
    aws s3api put-bucket-versioning \
      --bucket ${Bucket} \
      --versioning-configuration MFADelete=Disabled,Status=Enabled
    aws s3api put-bucket-lifecycle-configuration  \
      --bucket ${Bucket} \
      --lifecycle-configuration file://./lifecycle-rule-s3-very-short-term.json
  fi
  aws s3api get-bucket-tagging \
    --bucket ${Bucket} | \

done
