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

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  url = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
  
}

locals {

  policies = jsondecode(file("${path.module}/../aws-orgz-team-unit/policies.json"))
  groups = local.policies.groups

  readonly_permission_sets = {
    for group, name in local.groups : group => {
      name   = "byt-${group}"
      policy = jsonencode(local.policies.readonly_policy)
    }
  }

  full_access_permission_sets = {
    for group, name in local.groups : group => {
      name   = "byt-${group}-readonly"
      policy = jsonencode(local.policies.full_access_policy)
    }
  }

}

resource "aws_iam_role" "roles" {
  for_each = local.groups

  name = "${each.key}_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
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

resource "aws_iam_policy" "readonly_policy" {
  for_each = local.readonly_permission_sets

  name        = each.value.name
  description = "Readonly access policy"
  policy      = each.value.policy
}

resource "aws_iam_policy" "full_access_policy" {
  for_each = local.full_access_permission_sets

  name        = each.value.name
  description = "Full access policy"
  policy      = each.value.policy
}

resource "aws_iam_role_policy_attachment" "readonly_attachment" {
  for_each = local.groups

  role       = aws_iam_role.roles[each.key].name
  policy_arn = aws_iam_policy.readonly_policy[each.key].arn
}

resource "aws_iam_role_policy_attachment" "full_access_attachment" {
  for_each = local.groups

  role       = aws_iam_role.roles[each.key].name
  policy_arn = aws_iam_policy.full_access_policy[each.key].arn
}