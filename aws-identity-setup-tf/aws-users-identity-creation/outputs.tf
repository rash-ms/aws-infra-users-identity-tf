# output "user_ids" {
#   value = [for user in aws_iam_identity_center_user.users : user.id]
# }

# output "user_ids" {
#   value = [for user in null_resource.create_users : user.id]
# }
output "user_ids" {
  value = local.user_ids
}
