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
