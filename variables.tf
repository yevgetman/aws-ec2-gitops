# -----------------------------------------------------
# Required Variables
# -----------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the SSH key pair (must exist in AWS)"
  type        = string
}

# -----------------------------------------------------
# Optional Variables
# -----------------------------------------------------

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "OpenClaw VPS"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "environment" {
  description = "Environment tag (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access (default: open to all - restrict in production!)"
  type        = string
  default     = "0.0.0.0/0"
}
