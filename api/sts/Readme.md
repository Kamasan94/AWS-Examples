## Create a User with no permission

```sh
aws iam create-user --user-name stsmachine-user
aws iam create-access-key --user-name stsmachine-user --output table
```
## Copy the access key and secret here
aws configure

Then edit credentials file to change away from default profile

## Test who you are
aws sts get-caller-identity

code ~/.aws/credential
aws sts get-caller-identity --profile sts

aws s3 ls --profile sts

## Create a Role
chmod u+x bin/deploy


## Use new user credentials and assume role

aws iam put-user-policy \
    --user-name stsmachine-user \
    --policy-name StsAssumePolicy \
    --policy-document policy.json


aws sts assume-role \
--role-arn arn:aws:iam::137263334750:role/my-sts-fun-stack-StsRole-XDKC8iXC0eAv \
--role-session-name s3-sts-fun \
--profile sts


## Then add the output to credentials to create an assume conifguration