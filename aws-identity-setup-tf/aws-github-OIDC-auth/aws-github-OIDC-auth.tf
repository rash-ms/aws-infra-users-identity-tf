# resource "aws_iam_openid_connect_provider" "github_oidc" {
#     client_id_list  =   ["sts.amazonaws.com"]
#     thumbprint_list =   ["1b511abead59c6ce207077c0bf0e0043b1382612"]
#     url             =   "https://token.actions.githubusercontent.com"
# }

# resource "aws_iam_role" "github_actions" {
#   name               = var.github-action-name
#   assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
#   tags               = var.github-action-role-tags
# }

# resource "aws_iam_role_policy_attachment" "github_actions_admin_access_attach" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# data "aws_iam_policy_document" "assume_role_policy" {
#     statement {
#       actions = ["sts:AssumeRoleWithWebIdentity"]
#       effect  = "Allow"
#       principals {
#         type        =  "Federated"
#         identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
#       }
#       condition {
#         test     = "StringEquals"
#         variable = "token.actions.githubusercontent.com:aud"
#         values   = ["sts.amazonaws.com"]
#       }
#       condition {
#         test     = "StringLike"
#         variable = "token.actions.githubusercontent.com:sub"
#         values   = ["repo:rash-ms/*"]

#       }
#     }
# }


#######################################################

provider "aws" {
  alias  = "data_eng_dev"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::021891586814:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "data_eng_prod"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::021891586728:role/OrganizationAccountAccessRole"
  }
}


locals {

  policies_data = jsondecode(file("${path.module}/../aws-orgz-team-unit/policies.json"))
  policies      = local.policies_data.policies
  groups        = local.policies_data.groups

  account_ids = {
    "data-eng-DEV"  = "021891586814"  
    "data-eng-PROD" = "021891586728"  
  }
}

resource "aws_iam_openid_connect_provider" "github_oidc_dev" {
  provider = aws.data_eng_dev

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_openid_connect_provider" "github_oidc_prod" {
  provider = aws.data_eng_prod

  client_id_list  = ["sts.amazonaws.com"]
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_role" "roles_dev" {
  for_each = local.groups

  provider = aws.data_eng_dev

  name = "${each.key}_role"

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
  for_each = local.groups

  provider = aws.data_eng_prod

  name = "${each.key}_role"

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

resource "aws_iam_policy" "policies_dev" {
  for_each = local.policies

  provider = aws.data_eng_dev

  name        = "${each.key}-policy"
  description = "Policy for ${each.key}"
  policy      = jsonencode(each.value.full_access_policy)
}

resource "aws_iam_policy" "policies_prod" {
  for_each = local.policies

  provider = aws.data_eng_prod

  name        = "${each.key}-policy"
  description = "Policy for ${each.key}"
  policy      = jsonencode(each.value.readonly_policy)
}

resource "aws_iam_role_policy_attachment" "policy_attachment_dev" {
  for_each = local.groups

  provider = aws.data_eng_dev

  role       = aws_iam_role.roles_dev[each.key].name
  policy_arn = aws_iam_policy.policies_dev[each.key].arn
}

resource "aws_iam_role_policy_attachment" "policy_attachment_prod" {
  for_each = local.groups

  provider = aws.data_eng_prod

  role       = aws_iam_role.roles_prod[each.key].name
  policy_arn = aws_iam_policy.policies_prod[each.key].arn
}
