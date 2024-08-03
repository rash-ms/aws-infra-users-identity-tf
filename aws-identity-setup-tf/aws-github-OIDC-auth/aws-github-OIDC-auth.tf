provider "aws" {
  alias  = "bdt-data_eng_dev"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::021891586814:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "bdt-data_eng_prod"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::021891586728:role/OrganizationAccountAccessRole"
  }
}


resource "aws_iam_openid_connect_provider" "github_oidc_dev" {
  provider = aws.bdt-data_eng_dev

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_openid_connect_provider" "github_oidc_prod" {
  provider = aws.bdt-data_eng_prod

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_role" "roles_dev" {
  provider = aws.bdt-data_eng_dev

  name = "dev-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc_dev.arn
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

resource "aws_iam_role" "roles_prod" {
  provider = aws.bdt-data_eng_prod

  name = "prod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc_prod.arn
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

resource "aws_iam_role_policy_attachment" "policy_attachment_dev" {
  provider = aws.bdt-data_eng_dev

  role       = aws_iam_role.roles_dev.name
#   policy_arn = "arn:aws:iam::0219475372814:policy/dev-policy"
  policy_arn = "arn:aws:iam::021891586814:policy/bdt-data-org-dev-role-policy"
}

resource "aws_iam_role_policy_attachment" "policy_attachment_prod" {
  provider = aws.bdt-data_eng_prod

  role       = aws_iam_role.roles_prod.name
#   policy_arn = "arn:aws:iam::021464739328:policy/prod-policy"
  policy_arn = "arn:aws:iam::021891586728:policy/bdt-data-org-prod-role-policy"
}
