output "group_ids" {
  description = "The IDs of the created groups"
  value       = aws_iam_identity_center_group.groups
}

output "user_ids" {
  description = "The IDs of the created users"
  value       = aws_iam_identity_center_user.users
}

output "group_memberships" {
  description = "The memberships of the users in the groups"
  value       = aws_iam_identity_center_group_membership.group_memberships
}
