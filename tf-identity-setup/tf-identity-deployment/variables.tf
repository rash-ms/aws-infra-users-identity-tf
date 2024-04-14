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
