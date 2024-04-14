variable "teams" {
  type    = list(string)
  default = ["data-team", "security-team", "marketing-team"]
}

# variable "teams" {
#   description = "Map of teams to their environments and sub-environments."
#   type = map(object({
#     prod_sub_ous = list(string)
#     non_prod_sub_ous = list(string)
#   }))

#   default = {
#     "data-team" = {
#       prod_sub_ous = [],
#       non_prod_sub_ous = ["dev", "stg"]
#     },
#     "infrastructure-security-team" = {
#       prod_sub_ous = [],
#       non_prod_sub_ous = ["dev", "stg"]
#     },
#     "marketing-team" = {
#       prod_sub_ous = [],
#       non_prod_sub_ous = ["dev", "stg"]
#     },
#   }
# }


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
