variable "teams" {
  description = "List of teams with their unit and accounts"
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
}

variable "teams_and_accounts" {
  description = "List of teams with unit and account details"
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
}

variable "role_tags" {
  description = "Role tags for different environments"
  type = list(string)
  default = ["stg", "dev", "prod"]
}
