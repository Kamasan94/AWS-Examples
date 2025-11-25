## NACL

aws ec2 create-network-acl --vpc-id vpc-05148ee2117641332

## Get AMI for Amazon Linux 2

```sh
aws ec2 describe-images \
--owners amazon --filters "Name=name,Values=amzn2-ami
```