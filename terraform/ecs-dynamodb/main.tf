# Create an IAM policy with permissions to DynamoDB and assign it to taskRoleArn parameter

# Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "GameScores"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "GameTitle"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "GameTitle"
    type = "S"
  }

  attribute {
    name = "TopScore"
    type = "N"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  global_secondary_index {
    name               = "GameTitleIndex"
    hash_key           = "GameTitle"
    range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}

# IAM Policy
resource "aws_iam_policy" "policy" {
    name        = "AllowDynamoDB"
    path        = "/"
    description = "Allows Dynamo DB Access"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                "dynamodb:DescribeTable",
                "dynamodb:Query",
                "dynamodb:Scan"
            ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.basic-dynamodb-table.arn
      },
    ]
  })
}

resource "aws_iam_role" "dynamodb-role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = aws_iam_policy.policy.policy

  tags = {
    tag-key = "tag-value"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "mycluster" {
    name = "mycluseter"
    
    setting {
      name = "containerInsights"
      value = "enbled"
    }
}

resource "aws_ecs_task_definition" "service" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "service-first"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
    {
      name      = "second"
      image     = "service-second"
      cpu       = 10
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 443
          hostPort      = 443
        }
      ]
    }
  ])

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }

  task_role_arn = aws_iam_policy.policy.arn
}

resource "aws_ecs_service" "idk" {
    name    = "idk"
    cluster = aws_ecs_cluster.mycluster.id
    task_definition = aws_ecs_task_definition.service.arn
    desired_count = 3
    iam_role = aws_iam_role.dynamodb-role.arn
}