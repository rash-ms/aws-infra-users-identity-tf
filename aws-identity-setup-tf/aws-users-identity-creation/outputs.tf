output "user_ids" {
  value = local.user_ids
}

# Remove the duplicate user_ids output if it exists here
output "debug_mappings" {
  value = local.flattened_user_groups
}
