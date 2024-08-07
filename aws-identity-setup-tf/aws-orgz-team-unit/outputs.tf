# output "organization_id" {
#   value = aws_organizations_organization.org.id
# }

output "team_wrkspc_account_ids" {
  value = { for k, v in aws_organizations_account.team_wrkspc_account : k => v.id }
}


output "team_group_ids" {
  value = { for k, v in aws_identitystore_group.team_group : k => split("/", v.id)[1] }
}

output "account_map" {
  value = local.account_map
}



# output "team_group_ids" {
#   value = {for k, v in aws_identitystore_group.team_group : k => v.group_id}
# }

# output "group_ids" {
#   value = { for k, v in local.policy_group_mapping :
#     k => aws_identitystore_group.team_group[v].group_id }
# }
