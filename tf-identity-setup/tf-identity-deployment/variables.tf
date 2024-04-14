variable "teams" {
  type    = list(string)
  default = ["data-team", "security-team", "marketing-team"]
}

variable "common_environments" {
  description = "List of common environments for each team."
  type        = list(string)
  default     = ["Prod", "Non-prod"]
}

variable "sub_environments" {
  description = "List of sub-environments under the Non-prod environment."
  type        = list(string)
  default     = ["dev", "stg"]
}
