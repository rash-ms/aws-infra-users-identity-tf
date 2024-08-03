terraform {
  required_version = ">=v0.14.7"
  backend "s3" {
    bucket         = "byt-infra-users-identity-backend"
    key            = "terraform/complete-state"
    region         = "us-east-1"                
  }
}