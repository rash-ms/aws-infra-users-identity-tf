# Variable Definitions
variable "environment" {
  description = "Environment to provision resources for (e.g., dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "teams" {
  description = "List of team names"
  type        = list(string)
  default     = ["data-platform"]
  # default     = ["data-platform", "data-infra", "data-eng", "data-bi"]
}

variable "aws_policies_file" {
  description = "Path to AWS policies JSON file"
  type        = string
  default     = "aws_policies.json"
}

variable "team_group_info_file" {
  description = "Path to team group info JSON file"
  type        = string
  default     = "aws_team_group_info.json"
}

# variable "environment" {
#   description = "Environment to provision resources for (e.g., dev, prod)"
#   type        = string
#   validation {
#     condition     = contains(["dev", "prod"], var.environment)
#     error_message = "Environment must be 'dev' or 'prod'."
#   }
# }

# variable "teams" {
#   description = "List of team names"
#   type        = list(string)
#   default     = ["data-platform", "data-infra", "data-engineer", "BI"]
# }

# variable "aws_policies_file" {
#   description = "Path to AWS policies JSON file"
#   type        = string
#   default     = "aws_policies.json"
# }

# variable "team_group_info_file" {
#   description = "Path to team group info JSON file"
#   type        = string
#   default     = "aws_team_group_info.json"
# }
