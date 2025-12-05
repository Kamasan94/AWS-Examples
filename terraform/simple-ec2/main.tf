provider "aws" {
  region = "us-east-1"
}

# Data source that fetches data about
# the latest AWS AMI that matches the fileter
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "example" { # Unique resource address
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type #variables are in variable.tf file

  #vpc_security_group_ids  = [module.vpc.default_security_group_id]
  #subnet_id               = module.vpc.private_subnets[0]

  tags = {
    Name = var.instance_name
  }
}