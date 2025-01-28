variable "teams" {
  description = "List of teams"
  type        = list(string)
  default     = ["data-platform"]
}

variable "workspace" {
  description = "List of workspaces"
  type        = list(string)
  default     = ["prod", "dev"]
}

# variable "environment" {
#   description = "Environment to deploy to (dev or prod)"
#   type        = string
# }