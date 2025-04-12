locals {
  config_path = "./base_conf/${var.env}.json"
  config      = jsondecode(file(local.config_path))
}

provider "aws" {
  alias  = "target"
  region = "us-east-1"

  assume_role {
    role_arn = local.config.target_role_arn
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  provider = aws.target
  count    = 1

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "cicd_role" {
  provider = aws.target
  count    = 1

  name = local.config.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github[0].arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.config.github_org}/*:ref:refs/heads/${local.config.branch}"
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "deployment_policy" {
  provider = aws.target
  count    = 1

  name = "${local.config.role_name}-policy"
  role = aws_iam_role.cicd_role[0].name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      }
    ]
  })
}
