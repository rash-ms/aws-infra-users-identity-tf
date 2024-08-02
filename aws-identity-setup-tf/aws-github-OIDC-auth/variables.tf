output "iam_roles" {
  value = aws_iam_role.roles
}

output "iam_policies" {
  value = {
    readonly = data.aws_iam_policy.readonly_policy
    full_access = data.aws_iam_policy.full_access_policy
  }
}