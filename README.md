# AWS EC2 GitOps

Terraform configuration for deploying an EC2 instance on AWS using GitOps principles. Infrastructure changes are made through pull requests and automatically applied when merged to main.

## What This Creates

- EC2 instance (Amazon Linux 2023, t3.micro by default)
- Elastic IP (static public IP address)
- Security group with SSH, HTTP, and HTTPS access
- Encrypted root EBS volume

## Prerequisites

1. **AWS Account** with permissions to create EC2, VPC, and IAM resources
2. **SSH Key Pair** created in AWS EC2 console
3. **GitHub Repository** with Actions enabled
4. **(Optional) S3 Bucket** for Terraform state storage

## Quick Start

### 1. Clone and Configure

```bash
# Clone this repo (or use as template)
git clone <your-repo-url>
cd aws-ec2-gitops

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars
```

### 2. Set Up GitHub Secrets

Go to your GitHub repo → Settings → Secrets and variables → Actions

**Required Secrets:**
| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key with EC2 permissions |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |

**Optional Variables** (Settings → Secrets and variables → Actions → Variables):
| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_REGION` | `us-east-1` | AWS region |
| `SSH_KEY_NAME` | `my-key` | Name of your SSH key pair |
| `INSTANCE_NAME` | `OpenClaw VPS` | Name tag for the instance |

### 3. Create AWS Resources for State (Recommended)

For team use, store Terraform state remotely:

```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Optional: Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then uncomment and update the backend configuration in `providers.tf`.

### 4. Deploy

```bash
# Push to main to trigger deployment
git add .
git commit -m "Initial infrastructure"
git push origin main
```

Or create a PR to see the plan first, then merge.

## Usage

### Making Changes

1. Create a feature branch
2. Edit Terraform files
3. Open a PR → GitHub Actions runs `terraform plan`
4. Review the plan in the PR comments
5. Merge to main → GitHub Actions runs `terraform apply`

### Connecting to Your Server

After deployment, get the connection info:

```bash
# From Terraform output (if running locally)
terraform output ssh_command

# Or from AWS Console → EC2 → Instances → find your public IP
ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
```

### Destroying Infrastructure

**Option 1: GitHub Actions (Recommended)**
1. Go to Actions → Terraform Destroy
2. Click "Run workflow"
3. Type `destroy` to confirm

**Option 2: Locally**
```bash
terraform destroy
```

## File Structure

```
.
├── .github/
│   └── workflows/
│       ├── deploy.yml      # CI/CD pipeline
│       └── destroy.yml     # Manual destroy workflow
├── main.tf                 # EC2, Security Group, EIP
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # AWS provider & backend config
├── setup.sh                # Instance bootstrap script
├── terraform.tfvars.example
├── .gitignore
└── README.md
```

## Customization

### Change Instance Type

Edit `terraform.tfvars` or set the GitHub variable:
```hcl
instance_type = "t3.small"
```

### Add Software to Instance

Edit `setup.sh` to install packages on first boot. Uncomment the Docker, Node.js, or Nginx sections, or add your own.

### Restrict SSH Access

**Important for production!** Update `ssh_allowed_cidr`:
```hcl
# Your IP only
ssh_allowed_cidr = "203.0.113.50/32"
```

### Add More Ports

Add security group rules in `main.tf`:
```hcl
resource "aws_vpc_security_group_ingress_rule" "custom" {
  security_group_id = aws_security_group.server.id
  description       = "Custom port"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
```

### Use Ubuntu Instead of Amazon Linux

Replace the AMI data source in `main.tf`:
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

And update the instance to use `data.aws_ami.ubuntu.id`. Note: Ubuntu uses `ubuntu` as the default user, not `ec2-user`.

## Cost Estimate

- **t3.micro**: ~$7-8/month (or free tier eligible for 12 months)
- **Elastic IP**: Free while attached to running instance
- **EBS (20GB gp3)**: ~$1.60/month
- **Data transfer**: Varies by usage

## Troubleshooting

### "Key pair not found"
Create an SSH key pair in AWS Console → EC2 → Key Pairs

### "No default VPC"
This template uses the default VPC. If deleted, either recreate it or modify to specify a VPC ID.

### State lock errors
If a previous run failed, you may need to manually unlock:
```bash
terraform force-unlock <lock-id>
```

### View instance logs
```bash
# SSH in and check cloud-init logs
cat /var/log/user-data.log
cat /var/log/cloud-init-output.log
```

## Security Notes

- **Never commit `terraform.tfvars`** - it may contain sensitive values
- **Never commit `.pem` files** - SSH keys should stay local
- **Restrict SSH access** - Don't leave `0.0.0.0/0` in production
- **Use IAM roles** - For production, consider OIDC instead of access keys
- **Enable state encryption** - Use S3 bucket encryption for state files

## License

MIT
