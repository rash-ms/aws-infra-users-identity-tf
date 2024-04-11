# resource "aws_ssoadmin_permission_set" "example" {
#   name               = "example"
#   description        = "Example permission set"
#   instance_arn       = data.aws_ssoadmin_instance.sso_instance_id.arn
#   session_duration   = "PT1H"  
# }

# data "aws_ssoadmin_instance" "sso_instance_id" {
#   instance_id = "ssoins-7223bf3a79e5e698"
# }

# resource "aws_ssoadmin_account_assignment" "user_assignment" {
#   count              = length(var.users)
#   instance_arn       = data.aws_ssoadmin_instance.sso_instance_id.arn
#   target_id          = values(var.users)[count.index]["email"]
#   target_type        = "USER"
#   permission_set_arn = aws_ssoadmin_permission_set.example.arn
#   principal_id       = data.aws_ssoadmin_instance.sso_instance_id.identity_store_id
#   principal_type     = "USER"
# }

# resource "aws_ssoadmin_account_assignment" "group_assignment" {
#   count              = length(var.groups)
#   instance_arn       = data.aws_ssoadmin_instance.sso_instance_id.arn
#   target_id          = keys(var.groups)[count.index]
#   target_type        = "GROUP"
#   permission_set_arn = aws_ssoadmin_permission_set.example.arn
#   principal_id       = data.aws_ssoadmin_instance.sso_instance_id.identity_store_id
#   principal_type     = "GROUP"
# }

# locals {
#   managed_policies = flatten([
#     for permission in var.permissions_list : [
#       for policy in permission.managed_policies : {
#         permission_set_name = permission.name
#         policy_arn          = policy
#       }
#     ]
#   ])

#   managed_policy_arns = {
#     for policy in local.managed_policies :
#     "${policy.permission_set_name}.${policy.policy_arn}" => policy
#   }

#   sso_instance_arn  = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
#   identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]

#   account_groups = flatten([
#     for permission in var.permissions_list : [
#       for account_group in setproduct(permission.aws_accounts, permission.sso_groups) : {
#         permission_set_name = permission.name
#         account             = account_group[0]
#         group               = account_group[1]
#       }
#     ]
#   ])

#   account_group_assignments = {
#     for account_group in local.account_groups:
#     "${account_group.permission_set_name}.${account_group.account}.${account_group.group}" => account_group
#   }

#   groups = distinct([for account_group in local.account_groups : account_group.group])
# }


# resource "aws_ssoadmin_permission_set" "permset" {
#   for_each = {
#     for permission in var.permissions_list:
#     permission.name => permission
#     }
#   instance_arn     = local.sso_instance_arn
#   name             = each.value.name
#   description      = each.value.description
#   session_duration = each.value.session_duration
# }

# resource "aws_ssoadmin_managed_policy_attachment" "managed_policy" {
#   for_each           = local.managed_policy_arns
#   instance_arn       = local.sso_instance_arn
#   managed_policy_arn = each.value.policy_arn
#   permission_set_arn = aws_ssoadmin_permission_set.permset[each.value.permission_set_name].arn
# }

# resource "aws_ssoadmin_account_assignment" "assignment" {
#   for_each           = local.account_group_assignments
#   instance_arn       = local.sso_instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.permset[each.value.permission_set_name].arn
#   principal_id       = data.aws_identitystore_group.id_group[each.value.group].id
#   target_id          = each.value.account
#   principal_type     = "GROUP"
#   target_type         = "AWS_ACCOUNT"
# }


# data "aws_ssoadmin_instances" "sso" {}

# data "aws_identitystore_group" "id_group" {
#   for_each          = toset(local.groups)
#   identity_store_id = local.identity_store_id

#   filter {
#     attribute_path = "DisplayName"
#     attribute_value = each.key
#   }
# }