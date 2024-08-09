# provider "aws" {
#   alias  = "byt_data_eng_dev"
#   region = "us-east-1"
#   assume_role {
#     role_arn ="arn:aws:iam::022499035350:role/byt-data-org-dev-role"
#   }
# }

# provider "aws" {
#   alias  = "byt_data_eng_prod"
#   region = "us-east-1"
#   assume_role {
#     role_arn ="arn:aws:iam::022499035568:role/byt-data-org-prod-role"
#   }
# }

provider "aws" {
  alias  = var.alias
  region = "us-east-1"
  assume_role {
    role_arn = var.deployment_details.assume_role_arn
  }
}
