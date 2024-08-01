# CREATE AWS ORGANIZATION UNIT
locals {
  team_account_emails = jsondecode(file("${path.module}/team_emails.json")).team_account_emails
  team_env_pairs = flatten([
      for team in var.teams : [
        for env in var.workspace : {
          team = team,
          env  = env
        }
      ]
    ])

    account_map = {
      for pair in local.team_env_pairs : 
      "${pair.team}-${pair.env}" => pair
    }
 }


data "aws_organizations_organization" "existing" {}

# resource "aws_organizations_organization" "org" {
#   aws_service_access_principals = [
#     "cloudtrail.amazonaws.com",
#     "config.amazonaws.com",
#   ]

#   enabled_policy_types = [
#     "SERVICE_CONTROL_POLICY"
#   ]
# }

resource "aws_organizations_organizational_unit" "team" {
  for_each  = toset(var.teams)
  name      = each.value
  # parent_id = aws_organizations_organization.org.roots[0].id
  parent_id = data.aws_organizations_organization.existing.roots[0].id

  tags = {
    Name = "BDT - ${each.value}"
  }
}

resource "aws_organizations_organizational_unit" "team_env" {
  for_each  = local.account_map
  name      = each.value.env
  parent_id = aws_organizations_organizational_unit.team[each.value.team].id

  tags = {
    Name = "BDT - ${each.value.team} - ${each.value.env}"
  }
}

resource "aws_organizations_account" "team_env_account" {
  for_each  = local.account_map
  name      = "BDT - ${each.key}"
  email     = local.team_account_emails[each.key]
  parent_id = aws_organizations_organizational_unit.team_env[each.key].id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name = "BDT -  ${each.key}",
    Team = each.value.team,
    Environment = each.value.env
  }
}

# READ-ONLY POLICY
resource "aws_iam_policy" "readonly_policy" {
  name   = "readonly_policy"
  path   = "/"
  policy = jsonencode(local.policies.readonly_policy)
}

# FULL-ACCESS POLICY
resource "aws_iam_policy" "full_access_policy" {
  name   = "full_access_policy"
  path   = "/"
  policy = jsonencode(local.policies.full_access_policy)
}

# Create IAM groups and attach policies
resource "aws_iam_group" "readonly_group" {
  name = "readonly_group"

  # tags = {
  #   Name = "readonly_group"
  # }
}

resource "aws_iam_group_policy_attachment" "readonly_group_policy_attachment" {
  group      = aws_iam_group.readonly_group.name
  policy_arn = aws_iam_policy.readonly_policy.arn
}

resource "aws_iam_group" "full_access_group" {
  name = "full_access_group"

  # tags = {
  #   Name = "full_access_group"
  # }
}

resource "aws_iam_group_policy_attachment" "full_access_group_policy_attachment" {
  group      = aws_iam_group.full_access_group.name
  policy_arn = aws_iam_policy.full_access_policy.arn
}

# Create IAM users and add them to the appropriate group based on environment
resource "aws_iam_user" "env_user" {
  for_each = local.account_map
  name     = "env-${each.key}"

  tags = {
    Name        = "env-${each.key}"
    Team        = each.value.team
    Environment = each.value.env
  }
}

resource "aws_iam_user_group_membership" "env_user_group_membership" {
  for_each = aws_iam_user.env_user
  user     = each.value.name

  groups = [
    each.value.environment == "Prod" ? aws_iam_group.readonly_group.name : aws_iam_group.full_access_group.name
  ]
}

# CREATE IAM USERS AND ATTACH POLICY BASED ON ENVIRONMENT
# resource "aws_iam_user" "env_user" {
#   for_each = local.account_map
#   name     = "env-${each.key}"

#   tags = {
#     Name        = "env-${each.key}"
#     Team        = each.value.team
#     Environment = each.value.env
#   } 
# }


# resource " aws_iam_user_policy_attachment" "policy_attachment" {
#   for_each   =  aws_iam_user.env_user
#   user       = each.value.name
#   policy_arn = each.value.env == "Prod" ? aws_iam_policy.readonly_policy.arn : aws_iam_policy.full_access_policy.arn
# }