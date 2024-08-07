# output "organization_id" {
#   value = aws_organizations_organization.org.id
# }

output "team_wrkspc_account_ids" {
  value = { for k, v in aws_organizations_account.team_wrkspc_account : k => v.id }
}


output "account_map" {
  value = local.account_map
}

output "team_group_ids" {
  value = {for k, v in aws_identitystore_group.team_group : k => v.group_id}
}

output "group_ids" {
  value = { for group_name, display_name in local.policy_group_mapping :
    group_name => aws_identitystore_group.team_group[display_name].group_id }
}