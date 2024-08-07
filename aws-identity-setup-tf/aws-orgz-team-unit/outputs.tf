# output "organization_id" {
#   value = aws_organizations_organization.org.id
# }

output "team_wrkspc_account_ids" {
  value = { for k, v in aws_organizations_account.team_wrkspc_account : k => v.id }
}


output "account_map" {
  value = local.account_map
}

output "group_ids" {
  value = {for k, v in aws_identitystore_group.team_group : k => v.group_id}
}