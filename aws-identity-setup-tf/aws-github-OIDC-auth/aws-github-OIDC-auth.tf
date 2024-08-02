locals {

  policies_data = jsondecode(file("${path.module}/../aws-orgz-team-unit/policies.json"))
  groups        = local.policies_data.groups

  policies = {
    "data-eng-DEV"  = "arn:aws:iam::021891586814:policy/data-eng-DEV-fullAccess",
    "data-eng-PROD" = "arn:aws:iam::021891586728:policy/data-eng-PROD-readonly"
  }
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  client_id_list = ["sts.amazonaws.com"]
  url = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
  
}

resource "aws_iam_role" "roles" {
  for_each = local.groups

  name = "${each.key}_role"
  
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
          "token.actions.githubusercontent.com:sub" = "repo:rash-ms/*" 
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each = local.groups

  role       = aws_iam_role.roles[each.key].name
  policy_arn = local.policies[each.key]
}

