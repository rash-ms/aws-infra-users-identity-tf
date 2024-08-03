terraform {
  backend "s3" {
    bucket         = "bdt-infra-resources-backend"
    key            = "terraform/complete-state"
    region         = "us-east-1"
    encrypt        = true
  }
}
