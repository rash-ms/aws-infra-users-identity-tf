variable "teams" {
  description = "Map of teams to their environments and sub-environments."
  type = map(object({
    prod_sub_ous = list(string)
    non_prod_sub_ous = list(string)
  }))

  default = {
    "data-team" = {
      prod_sub_ous = [],
      non_prod_sub_ous = ["dev", "stg"]
    },
    "infrastructure-security-team" = {
      prod_sub_ous = [],
      non_prod_sub_ous = ["dev", "stg"]
    },
    "marketing-team" = {
      prod_sub_ous = [],
      non_prod_sub_ous = ["dev", "stg"]
    },
  }
}