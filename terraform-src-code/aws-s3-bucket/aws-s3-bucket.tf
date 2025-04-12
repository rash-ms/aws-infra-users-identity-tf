locals {
  config_path = "./base_conf/${var.environment}.json"
  config      = jsondecode(file(local.config_path))

  region      = local.config.region
  bucket_name = local.config.bucket_name
  role_arn    = local.config.role_arn
}

provider "aws" {
  alias  = "target"
  region = local.region

  assume_role {
    role_arn = local.role_arn
  }
}

# Create S3 bucket with Object Lock enabled (must be done at creation)
resource "aws_s3_bucket" "tf_backend" {
  provider            = aws.target
  bucket              = local.bucket_name
  force_destroy       = true
  object_lock_enabled = true

  tags = {
    Environment = var.environment
    Name        = "Terraform State Bucket"
  }
}

# Enable versioning (required for Object Lock)
resource "aws_s3_bucket_versioning" "versioning" {
  provider = aws.target
  bucket   = aws_s3_bucket.tf_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Object Lock configuration
resource "aws_s3_bucket_object_lock_configuration" "lock_config" {
  provider = aws.target
  bucket   = aws_s3_bucket.tf_backend.id

  rule {
    default_retention {
      mode = "GOVERNANCE" # or "COMPLIANCE"
      days = 30           # Optional: lock objects for 30 days
    }
  }
}

output "s3_backend_bucket" {
  value = local.bucket_name
}
