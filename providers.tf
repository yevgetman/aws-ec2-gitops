# -----------------------------------------------------
# Terraform Configuration
# -----------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # -----------------------------------------------------
  # Remote State Backend (S3)
  # 
  # SETUP INSTRUCTIONS:
  # 1. Create an S3 bucket for state storage
  # 2. Create a DynamoDB table for state locking (optional but recommended)
  # 3. Uncomment the backend block below and update values
  # -----------------------------------------------------

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ec2-gitops/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"  # Optional: for state locking
  # }
}

# -----------------------------------------------------
# AWS Provider
# -----------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "ec2-gitops"
      ManagedBy = "terraform"
    }
  }
}
