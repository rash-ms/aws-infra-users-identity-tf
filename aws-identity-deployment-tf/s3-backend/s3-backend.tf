terraform {
  required_version = ">=v0.14.7"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "backend" {
  bucket = "byt-infra-users-identity-backend" 
  tags = {
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_acl" "backend_acl" {
  bucket = aws_s3_bucket.backend.id
  acl    = "private"
}