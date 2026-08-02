# Run this layer FIRST with local backend, then migrate state to S3.
# See docs/runbooks/bootstrap.md for the exact commands.

# Computes a name suffix so resource names stay globally unique.
# If var.unique_id is non-empty, appends "-<id>"; otherwise leaves no suffix.
locals {
  name_suffix = var.unique_id != "" ? "-${var.unique_id}" : ""
}

# ──────────────────────────────────────────────
# S3 Bucket — Terraform Remote State
# ──────────────────────────────────────────────

# Central S3 bucket that will store all terraform.tfstate files for every layer.
# Versioning is mandatory so that state history is never lost on accidents.
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.org_name}-lz-terraform-state${local.name_suffix}"

  lifecycle {
    # Prevents accidental deletion of the bucket, which would destroy all state files.
    prevent_destroy = true
  }
}

# Enable versioning so every state file write is captured as a new version.
# This allows point-in-time recovery if a state file is corrupted.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state files at rest using AES-256 (SSE-S3).
# KMS-based encryption (SSE-KMS) will be added in M3 once the CMK is available.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the state bucket.
# State files contain sensitive resource metadata and must never be public.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────────
# DynamoDB Table — Terraform State Locking
# ──────────────────────────────────────────────

# DynamoDB table used by Terraform to lock state files during applies.
# Prevents concurrent runs from corrupting the state. PAY_PER_REQUEST avoids idle costs.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.org_name}-lz-terraform-locks${local.name_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    # Prevents accidental deletion of the lock table, which would break all layer operations.
    prevent_destroy = true
  }
}

# ──────────────────────────────────────────────
# GitHub Actions — OIDC Identity Provider
# ──────────────────────────────────────────────

# Registers GitHub Actions as a trusted OIDC identity provider in this AWS account.
# This enables keyless authentication from GitHub CI/CD pipelines via short-lived tokens.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # This thumbprint is the publicly documented fingerprint for GitHub's OIDC TLS certificate.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM role that GitHub Actions pipelines can assume via the OIDC provider.
# The trust policy restricts which GitHub org and repo are permitted to assume this role.
resource "aws_iam_role" "github_actions_oidc" {
  name = "${var.org_name}-lz-github-actions"

  # Trust policy: allow GitHub Actions from the specified org/repo to assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # Restricts to the configured GitHub org and repo. var.github_repo can be '*' to allow all.
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}
