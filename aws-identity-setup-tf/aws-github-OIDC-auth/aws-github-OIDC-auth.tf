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

data "aws_iam_policy" "readonly_policy" {
  for_each = { for k, v in local.groups : k => v if contains(k, "PROD") }
  arn      = "arn:aws:iam::637423205666:policy/${each.key}-readonly"
}

data "aws_iam_policy" "full_access_policy" {
  for_each = { for k, v in local.groups : k => v if contains(k, "DEV") }
  arn      = "arn:aws:iam::637423205666:policy/${each.key}-fullAccess"
}

resource "aws_iam_role_policy_attachment" "readonly_policy_attachment" {
  for_each = data.aws_iam_policy.readonly_policy

  role       = aws_iam_role.roles[each.key].name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "full_access_policy_attachment" {
  for_each = data.aws_iam_policy.full_access_policy

  role       = aws_iam_role.roles[each.key].name
  policy_arn = each.value.arn
}

# resource "aws_iam_role_policy_attachment" "policy_attachment" {
#   for_each = local.groups

#   role       = aws_iam_role.roles[each.key].name
#   policy_arn = contains(keys(local.policies[each.key]), "readonly_policy") ? aws_iam_policy.policies["${each.key}_readonly_policy"].arn : aws_iam_policy.policies["${each.key}_full_access_policy"].arn
# }






# data "aws_iam_policy" "readonly_policy" {
#   for_each = local.groups
#   arn      = "arn:aws:iam::637423205666:policy/byt-${each.key}-readonly"
# }

# data "aws_iam_policy" "full_access_policy" {
#   for_each = local.groups
#   arn      = "arn:aws:iam::637423205666:policy/byt-${each.key}-fullAccess"
# }

# resource "aws_iam_role_policy_attachment" "policy_attachment" {
#   for_each = local.groups

#   role       = aws_iam_role.roles[each.key].name
#   policy_arn = length(regexall(".*-PROD$", each.key)) > 0 ? data.aws_iam_policy.readonly_policy[each.key].arn : data.aws_iam_policy.full_access_policy[each.key].arn
#   # policy_arn = each.key == "prod" ? data.aws_iam_policy.readonly_policy[each.key].arn : data.aws_iam_policy.full_access_policy[each.key].arn
# }


# resource "aws_iam_policy" "readonly_policy" {
#   for_each = local.readonly_permission_sets

#   name        = each.value.name
#   description = "Readonly access policy"
#   policy      = each.value.policy
# }

# resource "aws_iam_policy" "full_access_policy" {
#   for_each = local.full_access_permission_sets

#   name        = each.value.name
#   description = "Full access policy"
#   policy      = each.value.policy
# }

# resource "aws_iam_role_policy_attachment" "readonly_attachment" {
#   for_each = local.groups

#   role       = aws_iam_role.roles[each.key].name
#   policy_arn = aws_iam_policy.readonly_policy[each.key].arn
# }

# resource "aws_iam_role_policy_attachment" "full_access_attachment" {
#   for_each = local.groups

#   role       = aws_iam_role.roles[each.key].name
#   policy_arn = aws_iam_policy.full_access_policy[each.key].arn
# }