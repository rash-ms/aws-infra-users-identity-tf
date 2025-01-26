provider "aws" {
  alias   = "assumed"
  region  = "us-east-1"
  profile = "shared-services"
  assume_role {
    role_arn     = "arn:aws:iam::${lookup(local.account_mapping, var.environment)}:role/terraform-role"
    session_name = "terraform-session"
  }
}

# Local variables for account mapping
locals {
  env = var.environment
  account_mapping = {
    dev  = "022499035350" # AWS Account ID for Dev
    prod = "022499035568" # AWS Account ID for Prod
  }
}

# resource "aws_iam_user" "example_user" {
#   provider = aws.assumed
#   name     = "example-user"
# }

# resource "aws_iam_policy" "example_policy" {
#   provider = aws.assumed
#   name     = "example-policy"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = ["s3:*"]
#         Resource = ["*"]
#       }
#     ]
#   })
# }

# resource "aws_iam_role" "example_role" {
#   provider = aws.assumed
#   name     = "example-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# variable "environment" {
#   description = "Environment to deploy to (dev or prod)"
#   type        = string
# }
