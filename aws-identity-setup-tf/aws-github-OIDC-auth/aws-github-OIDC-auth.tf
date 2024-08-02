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

locals {

  policies_data = jsondecode(file("${path.module}/../aws-orgz-team-unit/policies.json"))
  policies      = local.policies_data.policies
  groups        = local.policies_data.groups

  account_ids = {
    "data-eng-DEV"  = "021891586814"  
    "data-eng-PROD" = "021891586728"  
  }
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  for_each = local.account_ids

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
        Federated = aws_iam_openid_connect_provider.github_oidc[each.key == "data-eng-DEV" ? "data-eng-DEV" : "data-eng-PROD"].arn
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

resource "aws_iam_policy" "policies" {
  for_each = local.policies

  name        = "${each.key}-policy"
  description = "Policy for ${each.key}"
  policy      = each.key == "data-eng-DEV" ? jsonencode(each.value.full_access_policy) : jsonencode(each.value.readonly_policy)
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each = local.groups

  role       = aws_iam_role.roles[each.key].name
  policy_arn = local.policies[each.key].arn
}

