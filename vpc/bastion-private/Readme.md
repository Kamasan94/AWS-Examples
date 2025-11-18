## Launch EC2 instance as Bastion on the public subnet

aws ec2 run-instances \
--image-id ami-0cae6d6fe6048ca2c \
--count 1 \
--instance-type t2.micro \
--key-name test-vpc \
--security-group-ids sg-09c126e7808d6412f \
--subnet-id subnet-0a784460c1baff8cb \
--associate-public-ip-address