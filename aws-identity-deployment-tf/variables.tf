variable "teams" {
  description = "List of teams"
  type        = list(string)
  default     = ["data-org"]
}

variable "workspace" {
  description = "List of workspaces"
  type        = list(string)
  default     = ["PROD", "DEV"]
}


variable "github_action_name" {
  description = "The name for the GitHub Actions IAM role"
  type        = string
  default     = "GitHubAction-AssumeRole"
}

variable "github_action_role_tags" {
  description = "A map of tags to assign to the role"
  type        = map(string)
  default     = {
    RoleWorkspace-0 = "stg"
    RoleWorkspace-1 = "dev"
    RoleWorkspace-2 = "prod"
  }
}