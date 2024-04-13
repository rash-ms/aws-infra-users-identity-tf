variable "team_accounts" {
  type = map(object({
    name  = string
    email = string
  }))
}

variable "teams" {
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
}

variable "role_tags" {
  type    = list(string)
  default = ["stg", "dev", "prod"]
}


variable "teams_and_accounts" {
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
  default = [
    {
      name     = "prod"
      unit     = aws_organizations_organizational_unit.prod.id
      accounts = ["data-eng-prod", "data-analyst-prod", "data-science-prod"]
    },
    {
      name     = "stg"
      unit     = aws_organizations_organizational_unit.stg.id
      accounts = ["data-eng-stg", "data-analyst-stg", "data-science-stg"]
    },
    {
      name     = "dev"
      unit     = aws_organizations_organizational_unit.dev.id
      accounts = ["data-eng-dev", "data-analyst-dev", "data-science-dev"]
    }
  ]
}