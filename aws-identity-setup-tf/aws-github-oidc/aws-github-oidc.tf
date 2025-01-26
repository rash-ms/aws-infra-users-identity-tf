provider "aws" {
  region  = "us-east-1"
  profile = "shared-services"
  assume_role {
    role_arn     = "arn:aws:iam::${lookup(local.account_mapping, local.env)}:role/terraform-role"
    session_name = "terraform-session"
  }
}

# Local variables for account mapping
locals {
  env = var.environment
  account_mapping = {
    dev : "022499035350" # AWS Account ID for Dev
    prod : "022499035568" # AWS Account ID for Prod
  }
}

# OIDC provider resource
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM role for GitHub Actions
resource "aws_iam_role" "github_role" {
  name = "GitHubActionsRole-${local.env}"

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
            "token.actions.githubusercontent.com:sub": "repo:rash-ms/*"
          }
        }
      }
    ]
  })
}


# Attach AdministratorAccess policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
  role       = aws_iam_role.github_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Attach a policy to the terraform-role
resource "aws_iam_role_policy_attachment" "attach_policy_to_terraform_role" {
  role       = "terraform-role" # The name of the role being assumed
  policy_arn = "arn:aws:iam::${lookup(local.account_mapping, var.environment)}:policy/byt-data-org-${local.env}-policy"
}

# # OIDC-specific IAM policy
# resource "aws_iam_policy" "oidc_policy" {
#   name        = "OIDCProviderPermissions"
#   description = "Permissions to manage OIDC providers"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "iam:GetOpenIDConnectProvider",
#           "iam:CreateOpenIDConnectProvider",
#           "iam:UpdateOpenIDConnectProviderThumbprint",
#           "iam:DeleteOpenIDConnectProvider"
#         ],
#         Resource = "arn:aws:iam::*:oidc-provider/*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "iam:PassRole",
#           "iam:AttachRolePolicy",
#           "iam:CreateRole",
#           "iam:DeleteRole",
#           "iam:UpdateAssumeRolePolicy"
#         ],
#         Resource = "arn:aws:iam::*:role/*"
#       }
#     ]
#   })
# }

# # Attach OIDC policy to the terraform-role
# resource "aws_iam_role_policy_attachment" "attach_oidc_policy_to_terraform_role" {
#   role       = "terraform-role"
#   policy_arn = aws_iam_policy.oidc_policy.arn
# }


# # Attach AdministratorAccess policy to the IAM role
# resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
#   role       = aws_iam_role.github_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }


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
