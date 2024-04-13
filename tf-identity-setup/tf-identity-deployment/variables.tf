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