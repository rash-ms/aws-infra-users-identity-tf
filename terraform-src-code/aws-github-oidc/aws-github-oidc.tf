provider "aws" {
  alias  = "assume"
  region = var.region

  assume_role {
    role_arn = var.byt_admin_role_arn
  }
}

provider "aws" {
  alias  = "target"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/OrganizationAccountAccessRole"

  }
}

resource "aws_iam_openid_connect_provider" "github" {
  provider = aws.target

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" # GitHub Actions thumbprint
  ]
}

resource "aws_iam_role" "cicd_role" {
  provider = aws.target

  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/*"
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

  name = "${var.role_name}-policy"
  role = aws_iam_role.cicd_role.id

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
