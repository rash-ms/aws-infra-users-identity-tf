resource "aws_iam_openid_connect_provider" "github_oidc_byt_dev" {
  provider = aws.byt_data_eng_dev

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_openid_connect_provider" "github_oidc_byt_prod" {
  provider = aws.byt_data_eng_prod

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
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

resource "aws_iam_role" "roles_byt_prod" {
  provider = aws.byt_data_eng_prod

  name = "byt-github-oidc-prod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc_byt_prod.arn
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

resource "aws_iam_role_policy_attachment" "policy_attachment_byt_dev" {
  provider = aws.byt_data_eng_dev

  role       = aws_iam_role.roles_byt_dev.name
  policy_arn = "arn:aws:iam::022499035350:policy/byt-data-org-dev-policy"
}

resource "aws_iam_role_policy_attachment" "policy_attachment_byt_prod" {
  provider = aws.byt_data_eng_prod

  role       = aws_iam_role.roles_byt_prod.name
  policy_arn = "arn:aws:iam::022499035568:policy/byt-data-org-prod-policy"
}
