terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.management, aws.audit]
    }
  }
}

# STEP 1: Delegate Inspector Admin to Audit Account (Per Region)
resource "aws_inspector2_delegated_admin_account" "audit_admin" {
  provider   = aws.management
  account_id = var.audit_account_id
}

# STEP 2a: Enable Inspector for the Audit (Administrator) account itself
resource "aws_inspector2_enabler" "audit_account" {
  provider       = aws.audit
  account_ids    = [var.audit_account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]

  depends_on = [aws_inspector2_delegated_admin_account.audit_admin]
}

# STEP 2b: Associate all member accounts (excluding Audit)
resource "aws_inspector2_member_association" "members" {
  for_each   = toset([for id in var.all_account_ids : id if id != var.audit_account_id])
  provider   = aws.audit
  account_id = each.value

  depends_on = [aws_inspector2_enabler.audit_account]
}

# STEP 2c: Enable Inspector for all member accounts
resource "aws_inspector2_enabler" "member_accounts" {
  provider       = aws.audit
  account_ids    = [for id in var.all_account_ids : id if id != var.audit_account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]

  depends_on = [aws_inspector2_member_association.members]
}

# STEP 3: Auto-enable Inspector for any future/new accounts
resource "aws_inspector2_organization_configuration" "org_config" {
  provider = aws.audit

  auto_enable {
    ec2    = true
    ecr    = true
    lambda = true
  }

  depends_on = [
    aws_inspector2_delegated_admin_account.audit_admin,
    aws_inspector2_enabler.audit_account
  ]
}