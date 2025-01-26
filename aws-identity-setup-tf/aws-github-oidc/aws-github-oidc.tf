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
    dev : "022499035350"  # AWS Account ID for Dev
    prod : "022499035568" # AWS Account ID for Prod
  }
}

# OIDC provider resource
resource "aws_iam_openid_connect_provider" "github_oidc" {
  provider        = aws.assumed
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM role for GitHub Actions
resource "aws_iam_role" "github_role" {
  provider = aws.assumed
  name     = "GitHubActionsRole-${local.env}"

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
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:rash-ms/*"
          }
        }
      }
    ]
  })
}

# Attach AdministratorAccess policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_admin_policy" {
  provider   = aws.assumed
  role       = aws_iam_role.github_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
