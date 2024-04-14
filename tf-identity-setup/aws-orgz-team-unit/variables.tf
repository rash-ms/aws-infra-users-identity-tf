variable "teams" {
  type    = list(string)
}

variable "common_environments" {
  description = "List of common environments for each team."
  type        = list(string)
}

variable "sub_environments" {
  description = "List of sub-environments under the Non-prod environment."
  type        = list(string)
}
