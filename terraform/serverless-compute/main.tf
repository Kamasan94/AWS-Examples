# Provider
provider "aws" {
  region = "us-east-1"
}

######################################################################################

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

######################################################################################


# Create a VPC for the instance
# whenever you add a module, terraform init
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "SQS-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames = true
}


#####################################################################################
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
#####################################################################################
#IAM ROLE FOR THE NOTIFICATION TARGET
#resource "aws_iam_role" "notificaion_role" {
#  name = "asg_lifecycle_hook_role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Principal = {
#          Service = "autoscaling.amazonaws.com"
#        }
#        Action = "SQS:SendMessage",
#        Resource = aws_sqs_queue.my_queue.arn
#      }
#    ]
#  })
#}

#####################################################################################
# Autoscaling Group
resource "aws_placement_group" "computer" {
  name = "computer"
  strategy = "cluster"
}

resource "aws_launch_template" "my_launch_template" {
  name_prefix = "my_launch_template"
  image_id = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "computer_autoscaler" {
  name = "computer_autoscaler"
  max_size = "5"
  min_size = "2"
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 4
  force_delete = true
  placement_group = ""
  vpc_zone_identifier = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  launch_template {
    id = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

   
  #initial_lifecycle_hook {
  #  name = "lifecycle_compute_hook"
  #  default_result = "CONTINUE"
  #  heartbeat_timeout = 2000
  #  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  #  
  #  notification_target_arn = aws_sqs_queue.my_queue.arn
  #  role_arn = aws_iam_role.notificaion_role.arn
  #}

  tag {
    key = "Author"
    value = "marco.davanzo"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

}
#####################################################################################
#AUTOSCALING POLICY
resource "aws_autoscaling_policy" "queue_scaling_policy" {
  name = "sqs-queue-depth-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.computer_autoscaler.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 4
}
