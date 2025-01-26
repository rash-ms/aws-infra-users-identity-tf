# module "iam_oidc_deployment" {
#   source = "../aws-identity-setup-tf/aws-github-oidc"
# }


# Load accounts from the JSON file
locals {
  accounts = jsondecode(file("${path.module}/accounts.json"))
}

# Define a single global AWS provider
provider "aws" {
  region = "us-east-1" # Default region
}

# Dynamically configure OIDC for each account
module "aws_oidc_providers" {
  for_each = {
    for account in local.accounts : account.account_id => account
  }

  source = "../aws-identity-setup-tf/aws-github-oidc"
  account_id = each.value.account_id
  region     = each.value.region
  role_name  = "byt-data-org-${each.value.environment}-role"
  repo_sub   = each.value.repo_sub
  assume_role_arn = "arn:aws:iam::${each.value.account_id}:role/byt-data-org-${each.value.environment}-role"
}

# Attach Administrator Policy to IAM Role
resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
  for_each = { for account in local.accounts : account.account_id => account }

  role       = module.aws_oidc_providers[each.key].role_name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}





# locals {
#   # Directly parse the JSON file
#   accounts = jsondecode(file("${path.module}/account_github_oidc.json"))
# }

# module "aws_oidc_providers" {
#   for_each = {
#     for account in local.accounts : account.account_id => {
#       account_id = account.account_id,
#       region     = account.region,
#       role_name  = "byt-data-org-${account.environment}-role",
#       repo_sub   = account.repo_sub
#     }
#   }

#   # source     = "./modules/aws_oidc_provider"
#   source = "../aws-identity-setup-tf/aws-github-oidc"
#   account_id = each.value.account_id
#   region     = each.value.region
#   role_name  = each.value.role_name
#   repo_sub   = each.value.repo_sub
# }

# resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
#   for_each = { for account in local.accounts : account.account_id => account }

#   role       = module.aws_oidc_providers[each.key].role_name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }
