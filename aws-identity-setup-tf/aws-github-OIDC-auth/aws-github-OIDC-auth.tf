# resource "aws_iam_openid_connect_provider" "github_oidc_byt_dev" {
#   provider = aws.byt_data_eng_dev

#   client_id_list  = ["sts.amazonaws.com"]
#   url             = "https://token.actions.githubusercontent.com"
#   thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
# }

# resource "aws_iam_openid_connect_provider" "github_oidc_byt_prod" {
#   provider = aws.byt_data_eng_prod

#   client_id_list  = ["sts.amazonaws.com"]
#   url             = "https://token.actions.githubusercontent.com"
#   thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
# }

# resource "aws_iam_role" "roles_byt_dev" {
#   provider = aws.byt_data_eng_dev

#   name = "byt-github-oidc-dev-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.github_oidc_byt_dev.arn
#       },
#       Action = "sts:AssumeRoleWithWebIdentity",
#       Condition = {
#         StringEquals = {
#           "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
#           "token.actions.githubusercontent.com:sub" = "repo:rash-ms/*"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_role" "roles_byt_prod" {
#   provider = aws.byt_data_eng_prod

#   name = "byt-github-oidc-prod-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.github_oidc_byt_prod.arn
#       },
#       Action = "sts:AssumeRoleWithWebIdentity",
#       Condition = {
#         StringEquals = {
#           "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
#           "token.actions.githubusercontent.com:sub" = "repo:rash-ms/*"
#         }
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "policy_attachment_byt_dev" {
#   provider = aws.byt_data_eng_dev

#   role       = aws_iam_role.roles_byt_dev.name
#   policy_arn = "arn:aws:iam::022499035350:policy/byt-data-org-dev-policy"
# }

# resource "aws_iam_role_policy_attachment" "policy_attachment_byt_prod" {
#   provider = aws.byt_data_eng_prod

#   role       = aws_iam_role.roles_byt_prod.name
#   policy_arn = "arn:aws:iam::022499035568:policy/byt-data-org-prod-policy"
# }


# locals {
#   deployments = jsondecode(file("${path.module}/github-deployment.json"))
  
#   # Flatten the deployments structure for easier iteration
#   dynamic_configs = flatten([
#     for deployment_name, deployment_details in local.deployments : [
#       for alias, details in deployment_details : {
#         deployment_name = deployment_name
#         alias           = alias
#         role_name       = details.role_name
#         policy_arn      = details.policy_arn
#         assume_role_arn = details.assume_role_arn
#       }
#     ]
#   ])
# }

# provider "aws" {
#   alias  = "default"
#   region = "us-east-1"
# }

# resource "aws_iam_openid_connect_provider" "github_oidc" {
#   for_each = { for config in local.dynamic_configs : "${config.deployment_name}-${config.alias}" => config }

#   client_id_list  = ["sts.amazonaws.com"]
#   url             = "https://token.actions.githubusercontent.com"
#   thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]

#   provider = aws.default
# }

# resource "aws_iam_role" "roles" {
#   for_each = { for config in local.dynamic_configs : "${config.deployment_name}-${config.alias}" => config }

#   name = each.value.role_name

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Federated = aws_iam_openid_connect_provider.github_oidc[each.key].arn
#       },
#       Action = "sts:AssumeRoleWithWebIdentity",
#       Condition = {
#         StringEquals = {
#           "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
#           "token.actions.githubusercontent.com:sub" = "repo:rash-ms/${replace(each.value.deployment_name, "-deployment", "")}/*"
#         }
#       }
#     }]
#   })

#   provider = aws.default
# }

# resource "aws_iam_role_policy_attachment" "policy_attachment" {
#   for_each = { for config in local.dynamic_configs : "${config.deployment_name}-${config.alias}" => config }

#   role       = aws_iam_role.roles[each.key].name
#   policy_arn = each.value.policy_arn

#   provider = aws.default
# }
