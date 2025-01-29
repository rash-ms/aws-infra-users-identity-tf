# data "aws_organizations_organization" "existing" {}

# data "aws_ssoadmin_instances" "main" {}




# # ✅ Create AWS Organization if it doesn't exist
# resource "aws_organizations_organization" "org" {
#   count = data.aws_organizations_organization.existing.accounts == null ? 1 : 0

#   aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
#   enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
#   lifecycle { prevent_destroy = true }
# }

# # ✅ Get Organization Root ID safely
# locals {
#   org_root_id = try(
#     aws_organizations_organization.org[0].roots[0].id,
#     data.aws_organizations_organization.existing.roots[0].id
#   )
# }

# # ✅ Create Organizational Unit (OU) for each team
# resource "aws_organizations_organizational_unit" "team_ou" {
#   for_each  = toset(var.teams)
#   name      = each.key
#   parent_id = local.org_root_id  # Use the safe local reference
# }


# locals {
#   aws_policies        = jsondecode(file(var.aws_policies_file)).policies
#   aws_team_group_info = jsondecode(file(var.team_group_info_file)).team_group_details

#   env_policy_types = {
#     for env, policies in local.aws_policies :
#     env => keys(policies)
#   }

#   group_policies = merge([
#     for policy_type in local.env_policy_types[var.environment] :
#     lookup(local.aws_team_group_info.attach_group_policies, policy_type, {})
#   ]...)

#   group_mappings = {
#     for group_key, policy_name in local.group_policies :
#     group_key => {
#       policy_name = policy_name,
#       email       = lookup(local.aws_team_group_info.emails, group_key, null)
#     } if lookup(local.aws_team_group_info.emails, group_key, null) != null
#   }

#   selected_policies = local.aws_policies[var.environment]

#   permission_sets = {
#     for policy_type, policy_details in local.selected_policies :
#     "${var.environment}-${policy_details.name}" => {  
#       name   = policy_details.name,
#       policy = jsonencode({
#         Version   = policy_details.Version,
#         Statement = policy_details.Statement
#       })
#     }
#   }


# }

# resource "aws_organizations_account" "accounts" {
#   for_each  = local.group_mappings
#   name      = each.key
#   email     = each.value.email
#   parent_id = aws_organizations_organizational_unit.team_ou[replace(each.key, "-${var.environment}", "")].id
#   role_name = "OrganizationAccountAccessRole"

#   lifecycle {
#     precondition {
#       condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", each.value.email))
#       error_message = "Invalid email format for ${each.key}"
#     }
#   }
# }

# resource "aws_identitystore_group" "groups" {
#   for_each          = local.group_mappings
#   identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
#   display_name      = "${each.key}-group"
#   description       = "Access group for ${each.key}"
# }

# resource "aws_ssoadmin_permission_set" "policy_set" {
#   for_each         = local.permission_sets
#   instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
#   name             = each.value.name
#   description      = "${each.value.name} permissions for ${var.environment}"
#   session_duration = "PT1H"
# }

# resource "aws_ssoadmin_permission_set_inline_policy" "policy_attachment" {
#   for_each           = local.permission_sets
#   instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
#   permission_set_arn = aws_ssoadmin_permission_set.policy_set[each.key].arn
#   inline_policy      = each.value.policy
# }

# resource "aws_ssoadmin_account_assignment" "group_assignment" {
#   for_each = local.group_mappings

#   instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
#   permission_set_arn = aws_ssoadmin_permission_set.policy_set["${var.environment}-${each.value.policy_name}"].arn
#   principal_id       = aws_identitystore_group.groups[each.key].group_id
#   principal_type     = "GROUP"
#   target_id          = aws_organizations_account.accounts[each.key].id
#   target_type        = "AWS_ACCOUNT"
# }


data "aws_organizations_organization" "existing" {}
data "aws_ssoadmin_instances" "main" {}

resource "aws_organizations_organization" "org" {
  count = data.aws_organizations_organization.existing.accounts == null ? 1 : 0

  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
  lifecycle { prevent_destroy = true }
}

locals {
  org_root_id = try(
    aws_organizations_organization.org[0].roots[0].id,
    data.aws_organizations_organization.existing.roots[0].id
  )

  # Load configuration files
  aws_policies        = jsondecode(file(var.aws_policies_file)).policies
  aws_team_group_info = jsondecode(file(var.team_group_info_file)).team_group_details

  # Existing account handling
  existing_account_map = {
    for acc in data.aws_organizations_organization.existing.accounts :
    acc.email => acc
  }

  # Group mappings with team names
  group_mappings = {
    for group_key, policy_name in merge([
      for policy_type in keys(local.aws_policies[var.environment]) :
      local.aws_team_group_info.attach_group_policies[policy_type]
    ]...) :
    group_key => {
      policy_name = policy_name,
      email       = local.aws_team_group_info.emails[group_key],
      team_name   = split("-", group_key)[0]
    } if lookup(local.aws_team_group_info.emails, group_key, null) != null
  }

  # Account management
  accounts_to_create = {
    for k, v in local.group_mappings :
    k => v if !contains(keys(local.existing_account_map), v.email)
  }

  # Combined account reference
  all_accounts = merge(
    local.existing_account_map,
    { for k, v in aws_organizations_account.accounts : k => v }
  )

  # # Permission sets
  # permission_sets = {
  #   for policy_type, policy_details in local.aws_policies[var.environment] :
  #   "${var.environment}-${policy_details.name}" => {
  #     name   = policy_details.name,
  #     policy = jsonencode(policy_details)
  #   }
  # }

  permission_sets = {
    for policy_type, policy_details in local.aws_policies[var.environment] :
    "${var.environment}-${policy_details.name}" => {
      name   = policy_details.name,
      # Create policy document without the "name" field
      policy = jsonencode({
        Version   = policy_details.Version
        Statement = policy_details.Statement
      })
    }
  }

}

# Organizational Units
resource "aws_organizations_organizational_unit" "team_ou" {
  for_each  = toset([for k, v in local.group_mappings : v.team_name])
  name      = each.key
  parent_id = local.org_root_id
}

# Account creation (only for new accounts)
resource "aws_organizations_account" "accounts" {
  for_each  = local.accounts_to_create

  name      = each.key
  email     = each.value.email
  parent_id = aws_organizations_organizational_unit.team_ou[each.value.team_name].id
  role_name = "OrganizationAccountAccessRole"

  lifecycle {
    ignore_changes = [role_name]
    precondition {
      condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", each.value.email))
      error_message = "Invalid email format for ${each.key}"
    }
  }
}

# SSO Groups
resource "aws_identitystore_group" "groups" {
  for_each          = local.group_mappings
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = "${each.key}-group"
  description       = "Access group for ${each.key}"
}

# Permission Sets
resource "aws_ssoadmin_permission_set" "policy_set" {
  for_each         = local.permission_sets
  instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  name             = each.value.name
  description      = "${each.value.name} permissions for ${var.environment}"
  session_duration = "PT8H"
}

# Policy Attachments
resource "aws_ssoadmin_permission_set_inline_policy" "policy_attachment" {
  for_each           = aws_ssoadmin_permission_set.policy_set
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = each.value.arn
  inline_policy      = local.permission_sets[each.key].policy
}


# resource "aws_ssoadmin_permission_set_inline_policy" "policy_attachment" {
#   for_each           = aws_ssoadmin_permission_set.policy_set
#   instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
#   permission_set_arn = each.value.arn
#   inline_policy      = jsonencode({
#     Version   = jsondecode(local.permission_sets[each.key].policy).Version
#     Statement = jsondecode(local.permission_sets[each.key].policy).Statement
#   })
# }

# Account Assignments
resource "aws_ssoadmin_account_assignment" "group_assignment" {
  for_each = local.group_mappings

  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.policy_set["${var.environment}-${each.value.policy_name}"].arn
  principal_id       = aws_identitystore_group.groups[each.key].group_id
  principal_type     = "GROUP"
  target_id          = local.all_accounts[each.value.email].id
  target_type        = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_permission_set_inline_policy.policy_attachment
  ]
}