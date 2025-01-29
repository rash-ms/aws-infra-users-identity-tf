# locals {
#   aws_policies        = jsondecode(file(var.aws_policies_file)).policies
#   aws_team_group_info = jsondecode(file(var.team_group_info_file)).team_group_details

#   env_policy_types = {
#     "dev"  = ["privilege-access-policy"],
#     "prod" = [
#       "readonly-access-policy", 
#       "audit-access-policy"
#     ]
#   }

#   group_policies = merge([
#     for policy_type in local.env_policy_types[var.environment] :
#     local.aws_team_group_info.attach_group_policies[policy_type]
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
#     for policy_key, policy_details in local.selected_policies :
#     "${var.environment}-${policy_details.name}" => {
#       name   = policy_details.name,
#       policy = jsonencode({
#         Version   = policy_details.Version,
#         Statement = policy_details.Statement
#       })
#     }
#   }
# }

# output "debug_permission_set_keys" {
#   value = keys(local.permission_sets)
# }

# data "aws_organizations_organization" "existing" {}
# data "aws_ssoadmin_instances" "main" {}

# resource "aws_organizations_organization" "org" {
#   aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
#   enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
#   lifecycle { prevent_destroy = true }
#   depends_on = [data.aws_organizations_organization.existing]
# }

# resource "aws_organizations_organizational_unit" "team_ou" {
#   name      = "${var.environment}-teams"
#   parent_id = aws_organizations_organization.org.roots[0].id
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

#   permission_set_arn = try(aws_ssoadmin_permission_set.policy_set["${var.environment}-${each.value.policy_name}"].arn, null)

#   principal_id       = aws_identitystore_group.groups[each.key].group_id
#   principal_type     = "GROUP"
#   target_id          = aws_organizations_account.accounts[each.key].id
#   target_type        = "AWS_ACCOUNT"
# }



# resource "aws_identitystore_group" "groups" {
#   for_each          = local.group_mappings
#   identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
#   display_name      = "${each.key}-group"
#   description       = "Access group for ${each.key}"
# }

# resource "aws_organizations_account" "accounts" {
#   for_each  = local.group_mappings
#   name      = each.key
#   email     = each.value.email
#   parent_id = aws_organizations_organizational_unit.team_ou.id
#   role_name = "OrganizationAccountAccessRole"

#   lifecycle {
#     precondition {
#       condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", each.value.email))
#       error_message = "Invalid email format for ${each.key}"
#     }
#   }
# }
