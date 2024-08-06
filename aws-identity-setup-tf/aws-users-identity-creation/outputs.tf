output "existing_users" {
  description = "Existing users in the identity store"
  value       = module.identity.existing_users
}

output "existing_groups" {
  description = "Existing groups in the identity store"
  value       = module.identity.existing_groups
}
