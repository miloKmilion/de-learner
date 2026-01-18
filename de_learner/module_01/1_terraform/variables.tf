variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-north-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "terraform"
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
  default     = "data-lake-dev-milokmilo"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "de-learner"
}

variable "athena_database_name" {
  description = "Athena database name"
  type        = string
  default     = "demo_dataset"
}

variable "lifecycle_expiration_days" {
  description = "Days until objects expire"
  type        = number
  default     = 30
}
