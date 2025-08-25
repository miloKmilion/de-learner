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
  region  = "eu-north-1"   # Change to your preferred region
  profile = "terraform"    # Must match your AWS SSO profile
}

# ------------------------
# S3 Bucket
# ------------------------
resource "aws_s3_bucket" "data_lake_bucket" {
  bucket = "data-lake-dev-milokmilo"  # Must be globally unique
  force_destroy = true  # Allows bucket deletion even if objects exist

  tags = {
    Environment = "dev"
    Project     = "de-learner"
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
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
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
  name   = "demo_dataset"
  bucket = aws_s3_bucket.data_lake_bucket.bucket
}