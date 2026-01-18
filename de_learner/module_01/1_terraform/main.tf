terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# ------------------------
# S3 Bucket
# ------------------------
resource "aws_s3_bucket" "data_lake_bucket" {
  bucket        = var.bucket_name
  force_destroy = true  # Allows bucket deletion even if objects exist

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ------------------------
# S3 Versioning (separate resource)
# ------------------------
resource "aws_s3_bucket_versioning" "data_lake_bucket_versioning" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------
# S3 Lifecycle Rules
# ------------------------
resource "aws_s3_bucket_lifecycle_configuration" "data_lake_bucket_lifecycle" {
  bucket = aws_s3_bucket.data_lake_bucket.id

  rule {
    id     = "delete-old-objects"
    status = "Enabled"

    filter {}  # Applies to all objects

    expiration {
      days = var.lifecycle_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ---------------------------
# Athena database (BigQuery dataset equivalent)
# ---------------------------
resource "aws_athena_database" "dataset" {
  name   = var.athena_database_name
  bucket = aws_s3_bucket.data_lake_bucket.bucket
}
