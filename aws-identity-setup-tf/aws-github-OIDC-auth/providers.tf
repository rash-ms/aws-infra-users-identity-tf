provider "aws" {
  alias  = "byt_data_eng_dev"
  region = "us-east-1"
  assume_role {
    role_arn ="arn:aws:iam::022499035350:role/byt-data-org-dev-role"
  }
}

provider "aws" {
  alias  = "byt_data_eng_prod"
  region = "us-east-1"
  assume_role {
    role_arn ="arn:aws:iam::022499035568:role/byt-data-org-prod-role"
  }
}