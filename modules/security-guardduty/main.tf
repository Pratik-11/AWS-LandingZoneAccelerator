terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.management, aws.audit]
    }
  }
}

# STEP 1: Enable GuardDuty in Management Account
resource "aws_guardduty_detector" "management" {
  provider = aws.management
  enable   = true
}

# STEP 2: Delegate GuardDuty to Audit Account
resource "aws_guardduty_organization_admin_account" "audit_admin" {
  provider         = aws.management
  admin_account_id = var.audit_account_id
  depends_on       = [aws_guardduty_detector.management]
}

# STEP 3: Enable GuardDuty in Audit Account
resource "aws_guardduty_detector" "audit" {
  provider = aws.audit
  enable   = true
}

# STEP 4: Audit Account auto-enables for all members
resource "aws_guardduty_organization_configuration" "audit_org_config" {
  provider                         = aws.audit
  detector_id                      = aws_guardduty_detector.audit.id
  auto_enable_organization_members = "ALL"

  depends_on = [aws_guardduty_organization_admin_account.audit_admin]
}
variable "audit_account_id" {
  description = "The AWS Account ID of the Audit account"
  type        = string
}
output "management_detector_id" {
  value = aws_guardduty_detector.management.id
}

output "audit_detector_id" {
  value = aws_guardduty_detector.audit.id
}