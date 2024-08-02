variable "github-action-name" {
  description = "The name for the GitHub Actions IAM role"
  type        = string
}

variable "github-action-role-tags" {
  description = "A map of tags to assign to the role"
  type        = map(string)
}