variable "alias" {
  type = string
}


provider "aws" {
  alias  = var.alias
  region = "us-east-1"
  assume_role {
    role_arn = var.deployment_details.assume_role_arn
  }
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  provider = aws[var.alias]

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_role" "roles" {
  provider = aws[var.alias]

  name = var.deployment_details.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub" = "repo:rash-ms:${replace(var.alias, "-deployment", "")}/*"
        }
      }
    }]
  })
}


resource "aws_iam_role" "roles_byt_dev" {
  provider = aws.byt_data_eng_dev

  name = "byt-github-oidc-dev-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc_byt_dev.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub" = "repo:rash-ms/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  provider = aws[var.alias]

  role       = aws_iam_role.roles.name
  policy_arn = var.deployment_details.policy_arn
}