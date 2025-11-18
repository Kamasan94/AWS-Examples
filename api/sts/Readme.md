## Create a User with no permission

```sh
aws iam create-user --user-name stsmachine-user
aws iam create-access-key --user-name stsmachine-user --output table
```
Copy the access key and secret here
aws configure

Then edit credentials file to change away from default profile

Test who you are
aws sts get-caller-identity

code ~/.aws/credential
aws sts get-caller-identity --profile sts

aws s3 ls --profile sts

## Create a Role

## Use new user credentials and assume role