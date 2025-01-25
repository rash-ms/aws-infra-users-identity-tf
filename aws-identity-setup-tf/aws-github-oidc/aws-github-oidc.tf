locals {
  # Parse the JSON file and access the `result` key
  accounts = jsondecode(file("${path.module}/account_github_oidc.json")).result
}

# Single AWS provider
provider "aws" {
  region = "us-east-1"
}

# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_oidc" {
  for_each = { for account in local.accounts : account.account_id => account }

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_role" {
  for_each = { for account in local.accounts : account.account_id => account }

  name = "GitHubActionsRole-${each.value.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc[each.key].arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub": each.value.repo_sub
          }
        }
      }
    ]
  })
}


# resource "aws_iam_role" "github_role" {
#   for_each = { for account in local.accounts : account.account_id => account }

#   name = "GitHubActionsRole-${each.value.environment}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#         {
#             Effect = "Allow",
#             Principal = {
#               Federated = aws_iam_openid_connect_provider.github_oidc[each.key].arn
#             },
#             Action = "sts:AssumeRoleWithWebIdentity",
#             Condition = {
#                 StringEquals = {
#                     "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
#                 },
#                 StringLike = {
#                     "token.actions.githubusercontent.com:sub": each.value.repo_sub
#                 }
#             }
#         }
#     ]
# })
# }

# Attach Administrator Access Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
  for_each = { for account in local.accounts : account.account_id => account }

  role       = aws_iam_role.github_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
