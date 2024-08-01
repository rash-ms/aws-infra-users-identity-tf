# variable "teams" {
#   description = "List of team name"
#   type    = list(string)
#   default = ["data-eng-solution", "infra-team", "marketing-team"]
# }

# variable "workspace" {
#   description = "List of workspace for each team."
#   type        = list(string)
#   default     = ["Prod", "Non-prod"]
# }

variable "teams" {
  description = "List of teams"
  type        = list(string)
  default     = ["data-eng", "marketing_team"]
}

variable "workspace" {
  description = "List of environments"
  type        = list(string)
  default     = ["Prod", "NonProd"]
}

# variable "team_account_emails" {
#   description = "Map of team and environment to account email"
#   type        = map(string)
#   default = {
#     "dataorg-Prod" = "aws-bdt-dataorg-prod@bagitek.com"
#     "dataorg-NonProd" = "aws-bdt-dataorg-nonprod@bagitek.com"
#   }
# }
