# module "aws-github-OIDC-auth" {
#   source             = "../aws-identity-setup-tf/aws-github-OIDC-auth"
#   github_action_name    = var.github_action_name
#   github_action_role_tags = var.github_action_role_tags

#   providers = {
#     aws = aws.aws-us-east-1
#   }
# }