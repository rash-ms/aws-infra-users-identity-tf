# terraform {
#   required_version = ">=v0.14.7"
#   backend "s3" {}
# }

# provider "aws" {
#   alias  = "dev"
#   region = "us-east-1"

#   assume_role {
#     role_arn     = "arn:aws:iam::<DEV_ACCOUNT_ID>:role/CrossAccountAdminRole"
#     session_name = "terraform-dev-session"
#   }
# }

# provider "aws" {
#   alias  = "prod"
#   region = "us-east-1"

#   assume_role {
#     role_arn     = "arn:aws:iam::<PROD_ACCOUNT_ID>:role/CrossAccountAdminRole"
#     session_name = "terraform-prod-session"
#   }
# }
