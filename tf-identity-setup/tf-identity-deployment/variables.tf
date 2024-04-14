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


# variable "teams" {
#   description = "List of teams with their unit and organizational details"
#   type = list(object({
#     name     = string
#     unit     = string
#     accounts = list(string)
#   }))
# }

# variable "team_accounts" {
#   description = "Map of team accounts with names and email addresses"
#   type = map(object({
#     name  = string
#     email = string
#   }))
# }

# variable "teams_and_accounts" {
#   description = "List of teams and their account details"
#   type = list(object({
#     name     = string
#     unit     = string
#     accounts = list(string)
#   }))
# }

# variable "role_tags" {
#   description = "List of role tags used for differentiating environment roles"
#   type        = list(string)
#   default     = ["stg", "dev", "prod"]
# }
