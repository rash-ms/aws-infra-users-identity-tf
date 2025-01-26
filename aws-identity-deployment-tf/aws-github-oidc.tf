# module "iam_oidc_deployment" {
#   source = "../aws-identity-setup-tf/aws-github-oidc"
# }

locals {
  # Directly parse the JSON file
  accounts = jsondecode(file("${path.module}/account_github_oidc.json"))
}

module "aws_oidc_providers" {
  for_each = {
    for account in local.accounts : account.account_id => {
      account_id = account.account_id,
      region     = account.region,
      role_name  = "byt-data-org-${account.environment}-role",
      repo_sub   = account.repo_sub
    }
  }

  # source     = "./modules/aws_oidc_provider"
  source = "../aws-identity-setup-tf/aws-github-oidc"
  account_id = each.value.account_id
  region     = each.value.region
  role_name  = each.value.role_name
  repo_sub   = each.value.repo_sub
}