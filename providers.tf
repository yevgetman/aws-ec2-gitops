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
  # -----------------------------------------------------

  backend "s3" {
    bucket         = "openclaw-vps-terraform-state"
    key            = "ec2-gitops/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
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
