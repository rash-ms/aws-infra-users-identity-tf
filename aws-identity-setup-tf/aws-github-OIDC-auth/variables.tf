variable "workspaces" {
  description = "List of workspaces"
  type        = list(string)
#   default     = ["dev", "prod"]
  default     = ["byt_data_eng_dev", "byt_data_eng_prod"]
}

variable "role_arns" {
  description = "Map of workspace to role ARN"
  type        = map(string)
  default     = {
    dev  = "arn:aws:iam::022499035350:role/byt-data-org-dev-role",
    prod = "arn:aws:iam::022499035568:role/byt-data-org-prod-role"
  }
}

variable "policy_arns" {
  description = "Map of workspace to policy ARN"
  type        = map(string)
  default     = {
    dev  = "arn:aws:iam::022499035350:policy/byt-data-org-dev-policy",
    prod = "arn:aws:iam::022499035568:policy/byt-data-org-prod-policy"
  }
}


# variable "github_action_name" {
#   description = "The name for the GitHub Actions IAM role"
#   type        = string
#   default     = "GitHubAction-AssumeRole"
# }

# variable "github_action_role_tags" {
#   description = "A map of tags to assign to the role"
#   type        = map(string)
#   default     = {
#     RoleWorkspace-0 = "stg"
#     RoleWorkspace-1 = "dev"
#     RoleWorkspace-2 = "prod"
#   }
# }

