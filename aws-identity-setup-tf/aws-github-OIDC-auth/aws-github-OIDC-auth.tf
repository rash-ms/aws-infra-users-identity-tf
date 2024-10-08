locals {
  deployments = jsondecode(file("${path.module}/github-deployment.json"))
  
  dynamic_configs_dev = [
    for alias, details in local.deployments["develop-deployment"] : {
      alias           = alias
      role_name       = details.role_name
      policy_arn      = details.policy_arn
    }
  ]
  
  dynamic_configs_prod = [
    for alias, details in local.deployments["main-deployment"] : {
      alias           = alias
      role_name       = details.role_name
      policy_arn      = details.policy_arn
    }
  ]
}

resource "aws_iam_openid_connect_provider" "github_oidc_deployment_dev" {
  for_each = { for config in local.dynamic_configs_dev : config.alias => config }

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]

  provider = aws.dev
}

resource "aws_iam_openid_connect_provider" "github_oidc_deployment_prod" {
  for_each = { for config in local.dynamic_configs_prod : config.alias => config }

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]

  provider = aws.prod
}

resource "aws_iam_role" "roles_dev" {
  for_each = { for config in local.dynamic_configs_dev : config.alias => config }

  name = each.value.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc_deployment_dev[each.key].arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub" = "repo:rash-ms/develop/*"
        }
      }
    }]
  })

  provider = aws.dev
}

resource "aws_iam_role" "roles_prod" {
  for_each = { for config in local.dynamic_configs_prod : config.alias => config }

  name = each.value.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc_deployment_prod[each.key].arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub" = "repo:rash-ms/main/*"
        }
      }
    }]
  })

  provider = aws.prod
}

resource "aws_iam_role_policy_attachment" "policy_attachment_dev" {
  for_each = { for config in local.dynamic_configs_dev : config.alias => config }

  role       = aws_iam_role.roles_dev[each.key].name
  policy_arn = each.value.policy_arn

  provider = aws.dev
}

resource "aws_iam_role_policy_attachment" "policy_attachment_prod" {
  for_each = { for config in local.dynamic_configs_prod : config.alias => config }

  role       = aws_iam_role.roles_prod[each.key].name
  policy_arn = each.value.policy_arn

  provider = aws.prod
}
