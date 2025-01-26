# OIDC Provider
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM Role
resource "aws_iam_role" "github_role" {
  name = "GitHubActionsRole-${var.account_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub": var.repo_sub
          }
        }
      }
    ]
  })
}

# Outputs
output "role_name" {
  value = aws_iam_role.github_role.name
}




# provider "aws" {
#   region = "us-east-1"
# }

# provider "aws" {
#   for_each = { for account in local.accounts : account.account_id => account }
#   alias    = each.key
#   region   = each.value.region
# }


# locals {
#   accounts = [
#     { account_id = "111111111111", region = "us-east-1" },
#     { account_id = "222222222222", region = "us-east-1" },
#     { account_id = "333333333333", region = "us-west-2" }
#   ]
# }

# module "aws_oidc_providers" {
#   for_each = { for account in local.accounts : account.account_id => account }

#   source     = "./modules/aws_oidc_provider"
#   account_id = each.value.account_id
#   region     = each.value.region
# }




# resource "aws_iam_openid_connect_provider" "github_oidc" {
#   for_each = { for account in local.accounts : account.account_id => account }

#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
 

  # lifecycle {
  #   prevent_destroy = true 
  #   ignore_changes = [url, client_id_list, thumbprint_list]
  # }

# }

  # depends_on = [aws_iam_role.github_role]
  # lifecycle {
  #   ignore_changes = [url, client_id_list, thumbprint_list]
  # }

  #   lifecycle {
  #   prevent_destroy = true # Prevent accidental deletion
  #   ignore_changes = [url, client_id_list, thumbprint_list]
  # }

# resource "aws_iam_role" "github_role" {
#   for_each = { for account in local.accounts : account.account_id => account }

#   name = "GitHubActionsRole-${each.value.environment}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.github_oidc[each.key].arn
#         },
#         Action = "sts:AssumeRoleWithWebIdentity",
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
#           },
#           StringLike = {
#             "token.actions.githubusercontent.com:sub": each.value.repo_sub
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
#   for_each = { for account in local.accounts : account.account_id => account }

#   role       = aws_iam_role.github_role[each.key].name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }
