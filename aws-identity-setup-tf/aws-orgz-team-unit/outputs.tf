# output "organization_id" {
#   value = aws_organizations_organization.org.id
# }

# output "team_env_account_ids" {
#   value = { for k, v in aws_organizations_account.team_env_account : k => v.id }
# }


output "account_map" {
  value = local.account_map
}

output "created_teams" {
  value = local.created_teams
}
