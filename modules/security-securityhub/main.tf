terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.management, aws.audit]
    }
  }
}

# STEP 1: Enable Security Hub in Management Account
resource "aws_securityhub_account" "management" {
  provider = aws.management
  
  # Prevents turning on default standards automatically to control costs/noise if desired. 
  # Set to true if you want AWS Foundational Security Best Practices enabled automatically.
  enable_default_standards = true 
}

# STEP 2: Delegate Security Hub to Audit Account
resource "aws_securityhub_organization_admin_account" "audit_admin" {
  provider         = aws.management
  admin_account_id = var.audit_account_id
  depends_on       = [aws_securityhub_account.management]
}

# STEP 3: Enable Security Hub in Audit Account
resource "aws_securityhub_account" "audit" {
  provider                 = aws.audit
  enable_default_standards = true
}

# STEP 4: Audit Account auto-enables for all members in this region
resource "aws_securityhub_organization_configuration" "audit_org_config" {
  provider    = aws.audit
  auto_enable = true

  depends_on = [
    aws_securityhub_organization_admin_account.audit_admin,
    aws_securityhub_account.audit
  ]
}