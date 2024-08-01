# CREATE AWS ORGANIZATION UNIT
locals {
  team_account_emails = jsondecode(file("${path.module}/team_emails.json")).team_account_emails

  policies = jsondecode(file("${path.module}/policies.json"))

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

  readonly_permission_sets = {
    for k, v in local.account_map : k => {
      name   = "byt-${v.team}-${v.env}-readonly"
      policy = jsonencode(local.policies.readonly_policy)
    }
  }

  full_access_permission_sets = {
    for k, v in local.account_map : k => {
      name   = "byt-${v.team}-${v.env}-fullaccess"
      policy = jsonencode(local.policies.full_access_policy)
    }
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




# Create custom permission sets using the policies.json file
resource "aws_ssoadmin_permission_set" "readonly_permission_set" {
  for_each     = local.readonly_permission_sets
  instance_arn = data.aws_ssoadmin_instances.main.arn
  name         = each.value.name
  description  = "Read-only access to AWS resources for ${each.key}"
  session_duration = "PT1H"
  relay_state = "https://console.aws.amazon.com/"

  tags = {
    Name = each.value.name
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_inline_policy" {
  for_each             = aws_ssoadmin_permission_set.readonly_permission_set
  instance_arn         = data.aws_ssoadmin_instances.main.arn
  permission_set_arn   = each.value.arn
  inline_policy        = jsonencode(local.readonly_permission_sets[each.key].policy)
}

resource "aws_ssoadmin_permission_set" "full_access_permission_set" {
  for_each     = local.full_access_permission_sets
  instance_arn = data.aws_ssoadmin_instances.main.arn
  name         = each.value.name
  description  = "Full access to AWS resources for ${each.key}"
  session_duration = "PT1H"
  relay_state = "https://console.aws.amazon.com/"

  tags = {
    Name = each.value.name
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "full_access_inline_policy" {
  for_each             = aws_ssoadmin_permission_set.full_access_permission_set
  instance_arn         = data.aws_ssoadmin_instances.main.arn
  permission_set_arn   = each.value.arn
  inline_policy        = jsonencode(local.full_access_permission_sets[each.key].policy)
}

# Assign permission sets to users based on environment
resource "aws_ssoadmin_account_assignment" "readonly_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "Prod"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_permission_set[each.key].arn
  principal_id = local.team_account_emails[each.key]  # Email address of the user
  principal_type = "USER"
  target_id = aws_organizations_account.team_env_account[each.key].id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "full_access_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "NonProd"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arn
  permission_set_arn = aws_ssoadmin_permission_set.full_access_permission_set[each.key].arn
  principal_id = local.team_account_emails[each.key]  # Email address of the user
  principal_type = "USER"
  target_id = aws_organizations_account.team_env_account[each.key].id
  target_type = "AWS_ACCOUNT"
}

data "aws_ssoadmin_instances" "main" {}

# READ-ONLY POLICY
# resource "aws_iam_policy" "readonly_policy" {
#   name   = "readonly_policy"
#   path   = "/"
#   policy = jsonencode(local.policies.readonly_policy)
# }

# # FULL-ACCESS POLICY
# resource "aws_iam_policy" "full_access_policy" {
#   name   = "full_access_policy"
#   path   = "/"
#   policy = jsonencode(local.policies.full_access_policy)
# }

# # Create IAM groups and attach policies
# resource "aws_iam_group" "readonly_group" {
#   name = "readonly_group"

#   # tags = {
#   #   Name = "readonly_group"
#   # }
# }

# resource "aws_iam_group_policy_attachment" "readonly_group_policy_attachment" {
#   group      = aws_iam_group.readonly_group.name
#   policy_arn = aws_iam_policy.readonly_policy.arn
# }

# resource "aws_iam_group" "full_access_group" {
#   name = "full_access_group"

#   # tags = {
#   #   Name = "full_access_group"
#   # }
# }

# resource "aws_iam_group_policy_attachment" "full_access_group_policy_attachment" {
#   group      = aws_iam_group.full_access_group.name
#   policy_arn = aws_iam_policy.full_access_policy.arn
# }

# Create IAM users and add them to the appropriate group based on environment
# resource "aws_iam_user" "env_user" {
#   for_each = local.account_map
#   name     = "env-${each.value.team}-${each.value.env}"

#   tags = {
#     Name        = "env-${each.value.team}-${each.value.env}"
#     Team        = each.value.team
#     Environment = each.value.env
#   }
# }

# resource "aws_iam_user_group_membership" "env_user_group_membership" {
#   for_each = aws_iam_user.env_user
#   user     = each.value.name

#   groups = [
#     each.value.tags.Environment == "Prod" ? aws_iam_group.readonly_group.name : aws_iam_group.full_access_group.name
#   ]
# }


# Create IAM users and add them to the appropriate group based on environment
# resource "aws_iam_user" "env_user" {
#   for_each = local.account_map
#   name     = "env-${each.key}"

#   tags = {
#     Name        = "env-${each.key}"
#     Team        = each.value.team
#     Environment = each.value.env
#   }
# }

# resource "aws_iam_user_group_membership" "env_user_group_membership" {
#   for_each = aws_iam_user.env_user
#   user     = each.value.name

#   # groups = [
#   #   each.value.env == "Prod" ? aws_iam_group.readonly_group.name : aws_iam_group.full_access_group.name
#   # ]
#   groups = [
#     each.value["env"] == "Prod" ? aws_iam_group.readonly_group.name : aws_iam_group.full_access_group.name
#   ]
# }

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