# AWS EC2 GitOps — OpenClaw VPS

Terraform configuration for deploying and managing an EC2 instance on AWS using GitOps principles. Infrastructure changes are made through pull requests and automatically applied when merged to `master`.

## What This Creates

- **EC2 instance** — Amazon Linux 2023, t3.large (2 vCPU, 8 GB RAM), 20 GB encrypted gp3 root volume
- **Elastic IP** — Static public IP attached to the instance
- **Security group** — SSH (22), HTTP (80), HTTPS (443) inbound; all outbound
- **S3 remote state** — Centralized Terraform state with versioning and encryption
- **DynamoDB state lock** — Prevents concurrent modifications to infrastructure

## Architecture

```
Developer → git push master → GitHub Actions → terraform apply → AWS
Developer → open PR          → GitHub Actions → terraform plan  → PR comment
Developer → Actions tab      → Terraform Destroy (manual)       → teardown
```

All Terraform state is stored in S3 (`openclaw-vps-terraform-state`) with DynamoDB locking (`terraform-state-lock`), ensuring consistent state across all CI runs.

## Current Infrastructure

| Resource | Identifier | Details |
|---|---|---|
| EC2 Instance | `i-056cb6d7d6ac1f4f8` | Amazon Linux 2023, t3.large |
| Elastic IP | `eipalloc-0ee551a4225ca3652` | Static public IP |
| Security Group | `sg-0c19b2b3a2683edcb` | SSH, HTTP, HTTPS in; all out |
| S3 Bucket | `openclaw-vps-terraform-state` | Versioned, encrypted state |
| DynamoDB Table | `terraform-state-lock` | PAY_PER_REQUEST locking |

## Prerequisites

1. **AWS Account** with permissions to create EC2, VPC, S3, and DynamoDB resources
2. **SSH Key Pair** created in AWS EC2 console
3. **GitHub Repository** with Actions enabled
4. **AWS CLI** configured locally (`aws configure`) for any manual operations
5. **GitHub Personal Access Token** (fine-grained) with Contents and Workflows read/write permissions scoped to this repository

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/yevgetman/aws-ec2-gitops.git
cd aws-ec2-gitops

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars
```

### 2. Set Up GitHub Secrets

Go to your GitHub repo > Settings > Secrets and variables > Actions

**Required Secrets:**

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS access key with EC2 permissions |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |

**Optional Variables** (Settings > Secrets and variables > Actions > Variables):

| Variable | Default | Description |
|---|---|---|
| `AWS_REGION` | `us-east-1` | AWS region |
| `SSH_KEY_NAME` | `my-key` | Name of your SSH key pair |
| `INSTANCE_NAME` | `OpenClaw VPS` | Name tag for the instance |

### 3. Remote State Backend

The S3 backend and DynamoDB lock table are already configured in `providers.tf`. If deploying a fresh copy of this repo, create the backend resources first:

```bash
# Create S3 bucket for state
aws s3 mb s3://openclaw-vps-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket openclaw-vps-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 4. Deploy

```bash
git add .
git commit -m "Initial infrastructure"
git push origin master
```

Or create a PR to see the plan first, then merge.

## Usage

### Making Changes

1. Create a feature branch
2. Edit Terraform files
3. Open a PR > GitHub Actions runs `terraform plan` and posts results as a PR comment
4. Review the plan
5. Merge to `master` > GitHub Actions runs `terraform apply`

### Connecting to Your Server

```bash
# From the GitHub Actions output, or:
ssh -i ~/.ssh/your-key.pem ec2-user@<elastic-ip>
```

### Destroying Infrastructure

**Option 1: GitHub Actions (Recommended)**
1. Go to Actions > Terraform Destroy
2. Click "Run workflow"
3. Type `destroy` to confirm

**Option 2: CLI**
```bash
gh workflow run "Terraform Destroy" -f confirm=destroy --repo yevgetman/aws-ec2-gitops
```

## File Structure

```
.
├── .github/
│   └── workflows/
│       ├── deploy.yml              # Plan on PR, apply on push to master
│       └── destroy.yml             # Manual destroy with confirmation gate
├── main.tf                         # EC2, Security Group, EIP, SG rules
├── variables.tf                    # Input variables with defaults
├── outputs.tf                      # Instance ID, IP, SSH command, etc.
├── providers.tf                    # AWS provider + S3 backend config
├── setup.sh                        # EC2 bootstrap script (user data)
├── terraform.tfvars.example        # Template for local variable overrides
├── .gitignore                      # Excludes state, secrets, keys, IDE files
└── README.md
```

## Configuration Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | string | `us-east-1` | AWS region for all resources |
| `key_name` | string | *(required)* | Pre-existing SSH key pair name in AWS |
| `instance_name` | string | `OpenClaw VPS` | Name tag for the EC2 instance |
| `instance_type` | string | `t3.micro` | EC2 instance size |
| `root_volume_size` | number | `20` | Root EBS volume size in GB |
| `environment` | string | `dev` | Environment tag |
| `ssh_allowed_cidr` | string | `0.0.0.0/0` | CIDR allowed for SSH access |

## GitHub Actions Workflows

### Terraform Deploy (`deploy.yml`)

Triggered on every push to `master` and every PR against `master`.

- **On PR:** Runs `terraform plan`, posts formatted results as a PR comment with status indicators for format check, init, validate, and plan
- **On push to master:** Runs `terraform plan` then `terraform apply -auto-approve`
- Uses Terraform 1.7.0 and AWS provider ~> 5.0

### Terraform Destroy (`destroy.yml`)

Manual trigger only (`workflow_dispatch`). Requires typing `"destroy"` as confirmation. A second job explicitly rejects and fails the workflow if the confirmation doesn't match.

## Bootstrap Script (`setup.sh`)

Runs once on first EC2 boot via user data:

1. System update (`dnf update`)
2. Installs common tools: git, vim, htop, curl, wget, unzip, jq, tree
3. Creates `/opt/app` directory for application deployment
4. Logs output to `/var/log/user-data.log`

**Optional sections** (uncomment as needed): Docker, Node.js, Nginx, firewalld.

## Customization

### Change Instance Type

Edit `terraform.tfvars` or set the `INSTANCE_NAME` GitHub variable:
```hcl
instance_type = "t3.small"
```

### Add Software to Instance

Edit `setup.sh` to install packages on first boot. Uncomment the Docker, Node.js, or Nginx sections, or add your own.

### Restrict SSH Access

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

Update the instance to use `data.aws_ami.ubuntu.id`. Note: Ubuntu uses `ubuntu` as the default user, not `ec2-user`.

## Cost Estimate

| Resource | Estimate | Notes |
|---|---|---|
| t3.large EC2 | ~$60/month | 2 vCPU, 8 GB RAM |
| Elastic IP | Free | While attached to a running instance |
| EBS (20 GB gp3) | ~$1.60/month | Encrypted |
| S3 state bucket | < $0.01/month | Minimal storage |
| DynamoDB lock table | < $0.01/month | PAY_PER_REQUEST, minimal usage |
| **Total** | **~$62/month** | |

## Troubleshooting

### "Key pair not found"
Create an SSH key pair in AWS Console > EC2 > Key Pairs.

### "No default VPC"
This configuration uses the default VPC. If deleted, recreate it or modify `main.tf` to specify a VPC ID.

### State lock errors
If a previous run failed mid-apply, you may need to manually unlock:
```bash
terraform force-unlock <lock-id>
```

### Importing existing resources
If resources exist in AWS but not in Terraform state (e.g., after enabling the S3 backend), import them:
```bash
terraform import -var="key_name=my-key" -var="instance_name=OpenClaw VPS" \
  aws_instance.server <instance-id>
```
If `terraform import` fails locally due to provider timeouts, create a temporary GitHub Actions workflow to run the imports on CI runners.

### View instance logs
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
cat /var/log/user-data.log
cat /var/log/cloud-init-output.log
```

## Security Notes

- **Never commit `terraform.tfvars`** — it may contain sensitive values
- **Never commit `.pem` files** — SSH keys should stay local
- **Restrict SSH access** — change `ssh_allowed_cidr` from `0.0.0.0/0` in production
- **Use fine-grained PATs** — scope GitHub tokens to this repository only, with minimal permissions
- **Use IAM roles** — for production, consider OIDC authentication instead of access keys
- **State encryption** — the S3 backend is configured with `encrypt = true`

## License

MIT
