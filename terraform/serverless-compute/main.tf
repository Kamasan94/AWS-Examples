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

# EC2 INSTANCES #
resource "aws_instance" "instance_1" { # Unique resource address
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type #variables are in variable.tf file

  vpc_security_group_ids  = [module.vpc.default_security_group_id]
  subnet_id               = module.vpc.private_subnets[0]

  tags = {
    Name = var.instance_name
    Author = "marco.davanzo"
  }
}

resource "aws_instance" "instance_2" { # Unique resource address
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type #variables are in variable.tf file

  vpc_security_group_ids  = [module.vpc.default_security_group_id]
  subnet_id               = module.vpc.private_subnets[0]

  tags = {
    Name = var.instance_name
    Author = "marco.davanzo"
  }
}

# AMAZON SQS
resource "aws_sqs_queue" "my_queue" {
  name                      = "job-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount = 4
  })

  tags = {
    Author = "marco.davanzo"
  }

  region = "us-east-1"
}

resource "aws_sqs_queue" "terraform_queue_deadletter" {
  name = "my-deadletter-queue"
}


# Autoscaling Group
resource "aws_placement_group" "computer" {
  name = "computer"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "computer_autoscaler" {
  name = "computer_autoscaler"
  max_size = "5"
  min_size = "2"
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 4
  force_delete = true
  placement_group = aws_placement_group.computer.id
  
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