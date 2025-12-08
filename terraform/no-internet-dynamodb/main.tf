# Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC for the instance
# whenever you add a module, terraform init
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "dynamodb-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames = true
}

# Generate a gateway endpoint for DynamoDB (internal AWS service)
# Then add it to the route tables of the private subnets
resource "aws_vpc_endpoint" "dynamodb_gateway_endpoint" {
    vpc_id              = module.vpc.vpc_id
    service_name        = "com.amazonaws.us-east-1.dynamodb"
    vpc_endpoint_type   =  "Gateway"

    route_table_ids = module.vpc.private_route_table_ids

    tags = {
      Name = "DynamoDB-Gateway-Endpoint"
    }
}