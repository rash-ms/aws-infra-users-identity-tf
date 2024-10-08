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
