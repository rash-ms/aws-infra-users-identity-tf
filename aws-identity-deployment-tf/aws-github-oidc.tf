module "iam_oidc_deployment" {
  source = "../aws-identity-setup-tf/aws-github-oidc"
  environment = var.environment
}

module "iam_oidc_deployment" {
  source = "../aws-identity-setup-tf/clone_aws-github-oidc"
  environment = var.environment
}

variable "environment" {
  description = "Environment to deploy to (dev or prod)"
  type        = string
}


# # Load accounts from JSON file
# locals {
#   accounts = jsondecode(file("${path.module}/accounts.json"))
# }

# # Define a single global provider (no for_each in provider)
# provider "aws" {
#   region = "us-east-1" # Default region
# }

# # Dynamically assume roles for each account
# module "aws_oidc_providers" {
#   source = "./modules/aws_oidc_provider"

#   for_each = {
#     for account in local.accounts : account.account_id => account
#   }

#   account_id = each.value.account_id
#   region     = each.value.region
#   role_name  = "byt-data-org-${each.value.environment}-role"
#   repo_sub   = each.value.repo_sub

#   providers = {
#     aws = aws
#   }
# }

# # Attach Administrator Policy to IAM Role
# resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
#   for_each = { for account in local.accounts : account.account_id => account }

#   role       = module.aws_oidc_providers[each.key].role_name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }






# # locals {
# #   # Directly parse the JSON file
# #   accounts = jsondecode(file("${path.module}/account_github_oidc.json"))
# # }

# # module "aws_oidc_providers" {
# #   for_each = {
# #     for account in local.accounts : account.account_id => {
# #       account_id = account.account_id,
# #       region     = account.region,
# #       role_name  = "byt-data-org-${account.environment}-role",
# #       repo_sub   = account.repo_sub
# #     }
# #   }

# #   # source     = "./modules/aws_oidc_provider"
# #   source = "../aws-identity-setup-tf/aws-github-oidc"
# #   account_id = each.value.account_id
# #   region     = each.value.region
# #   role_name  = each.value.role_name
# #   repo_sub   = each.value.repo_sub
# # }

# # resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
# #   for_each = { for account in local.accounts : account.account_id => account }

# #   role       = module.aws_oidc_providers[each.key].role_name
# #   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# # }
