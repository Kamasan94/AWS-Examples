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

# Component of infrastructure
resource "aws_instance" "app_server" { # Unique resource address
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type #variables are in variable.tf file

  vpc_security_group_ids  = [module.vpc.default_security_group_id]
  subnet_id               = module.vpc.private_subnets[0]

  tags = {
    Name = var.instance_name
  }
}

# Create a VPC for the instance
# whenever you add a module, terraform init
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames = true
}