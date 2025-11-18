## Create the bucket
aws s3api create-bucket \
    --bucket schrodingercorp-content-prod \
    --region us-east-1

## Create folders 
aws s3api put-object \
--bucket schrodingercorp-content-prod \
--key public/ \
--content-length 0

aws s3api put-object \
--bucket schrodingercorp-content-prod \
--key protected/ \
--content-length 0

aws s3api put-object \
--bucket schrodingercorp-content-prod \
--key internal/ \
--content-length 0

## Create IAM Users
aws iam create-group --group-name InternalUsers

## Create the bucket for Server Access Logging
aws s3api create-bucket \
    --bucket schrodingercorp-content-logging \
    --region us-east-1

## Get the bucket policy
aws s3api put-bucket-policy --bucket schrodingercorp-content-logging \
--policy file://schrodinger-logging-policy.json
