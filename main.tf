terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ==============================================================================
# Step 2: $10.00 Monthly Budget with 80% Threshold Email Notification
# ==============================================================================
resource "aws_budgets_budget" "tlab_budget" {
  name         = "TLAB-Strict-Budget"
  budget_type  = "COST"
  limit_amount = "10.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["kennethcardona07@gmail.com"]
  }
}

# ==============================================================================
# Step 3: Dynamic Private S3 Bucket
# ==============================================================================
resource "random_id" "id" {
  byte_length = 4
}

resource "aws_s3_bucket" "vault" {
  bucket        = "titan-fintech-vault-kc-${random_id.id.hex}"
  force_destroy = true
}

# Enforce private-by-default access
resource "aws_s3_bucket_public_access_block" "vault_privacy" {
  bucket = aws_s3_bucket.vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# Step 4: Least-Privilege IAM Role & Scoped Policy
# ==============================================================================
# 1. IAM Role with EC2 Trust Policy
resource "aws_iam_role" "ec2_vault_role" {
  name = "Titan-EC2-Vault-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Scoped Policy: ONLY s3:PutObject on this specific bucket ARN
resource "aws_iam_policy" "s3_put_only" {
  name        = "Titan-S3-PutObject-Policy"
  description = "Allows only PutObject actions strictly to the vault bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.vault.arn}/*"
      }
    ]
  })
}

# 3. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "attach_s3_put" {
  role       = aws_iam_role.ec2_vault_role.name
  policy_arn = aws_iam_policy.s3_put_only.arn
}

# 4. Instance Profile to bridge Role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "Titan-EC2-Vault-Instance-Profile"
  role = aws_iam_role.ec2_vault_role.name
}

# ==============================================================================
# Step 5: EC2 Instance (t2.micro) with Attached IAM Role
# ==============================================================================
resource "aws_instance" "app_server" {
  ami                  = "ami-080e1f13689e07408" # Ubuntu 22.04 LTS (us-east-1)
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Titan-Vault-App-Server"
  }
}