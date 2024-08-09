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

variable "identity_store_id" {
  type        = string
  description = "The Identity Store ID for the AWS SSO instance."
}