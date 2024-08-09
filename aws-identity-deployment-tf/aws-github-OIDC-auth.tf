locals {
  deployments = jsondecode(file("${path.module}/github-deployment.json"))
}

module "iam_deployment" {
  for_each = local.deployments

  source = "../aws-identity-setup-tf/aws-github-OIDC-auth"

  alias = keys(each.value)[0]
  deployment_details = lookup(each.value, keys(each.value)[0], {})
}


# module "aws-github-OIDC-auth" {
#   source                  = "../aws-identity-setup-tf/aws-github-OIDC-auth"
#   github_action_name      = var.github_action_name
#   github_action_role_tags = var.github_action_role_tags
# }


# variable "github_action_name" {
#   description = "The name for the GitHub Actions IAM role"
#   type        = string
#   default     = "GitHubAction-AssumeRole"
# }

# variable "github_action_role_tags" {
#   description = "A map of tags to assign to the role"
#   type        = map(string)
#   default     = {
#     RoleWorkspace-0 = "stg"
#     RoleWorkspace-1 = "dev"
#     RoleWorkspace-2 = "prod"
#   }
# }