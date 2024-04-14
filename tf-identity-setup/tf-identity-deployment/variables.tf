# variable "teams" {
#   type    = list(string)
#   default = ["data-team", "security-team", "marketing-team"]
# }



variable "teams" {
  type    = list(string)
  # Assume default is provided by the module caller or you can set a default here
}