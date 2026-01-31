#!/bin/bash
# -----------------------------------------------------
# EC2 User Data Bootstrap Script
# This runs once on first boot
# -----------------------------------------------------

set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting bootstrap at $(date)"

# -----------------------------------------------------
# System Updates
# -----------------------------------------------------

echo "Updating system packages..."
dnf update -y

# -----------------------------------------------------
# Install Common Tools
# -----------------------------------------------------

echo "Installing common tools..."
dnf install -y \
    git \
    vim \
    htop \
    wget \
    unzip \
    jq \
    tree
# Note: curl-minimal is pre-installed on Amazon Linux 2023 and conflicts
# with the full curl package. curl-minimal works identically for standard use.

# -----------------------------------------------------
# Install Docker (optional - uncomment if needed)
# -----------------------------------------------------

# echo "Installing Docker..."
# dnf install -y docker
# systemctl enable docker
# systemctl start docker
# usermod -aG docker ec2-user

# -----------------------------------------------------
# Install Node.js (optional - uncomment if needed)
# -----------------------------------------------------

# echo "Installing Node.js..."
# dnf install -y nodejs npm

# -----------------------------------------------------
# Install Nginx (optional - uncomment if needed)
# -----------------------------------------------------

# echo "Installing Nginx..."
# dnf install -y nginx
# systemctl enable nginx
# systemctl start nginx

# -----------------------------------------------------
# Configure Firewall (if needed)
# -----------------------------------------------------

# Note: AWS Security Groups handle firewall rules externally
# Only uncomment if you need host-level firewall as well

# systemctl enable firewalld
# systemctl start firewalld
# firewall-cmd --permanent --add-service=http
# firewall-cmd --permanent --add-service=https
# firewall-cmd --reload

# -----------------------------------------------------
# Create Application Directory
# -----------------------------------------------------

echo "Creating application directory..."
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

# -----------------------------------------------------
# Setup Complete
# -----------------------------------------------------

echo "Bootstrap completed at $(date)"
echo "System is ready!"
