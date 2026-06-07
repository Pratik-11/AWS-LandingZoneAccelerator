# ──────────────────────────────────────────────
# AWS Config Outputs
# ──────────────────────────────────────────────

output "config_audit_aggregator_arn" {
  description = "The ARN of the AWS Config Aggregator running in the Audit account"
  value       = aws_config_configuration_aggregator.audit_aggregator.arn
}

output "config_delegated_admin_account_id" {
  description = "The account ID designated as the delegated administrator for AWS Config"
  value       = aws_organizations_delegated_administrator.config_admin.account_id
}

# ──────────────────────────────────────────────
# Amazon GuardDuty Outputs
# ──────────────────────────────────────────────

output "guardduty_use1_management_detector_id" {
  description = "The GuardDuty Detector ID in the Management account (us-east-1)"
  value       = module.guardduty_use1.management_detector_id
}

output "guardduty_use1_audit_detector_id" {
  description = "The GuardDuty Detector ID in the Audit account (us-east-1)"
  value       = module.guardduty_use1.audit_detector_id
}

output "guardduty_aps1_management_detector_id" {
  description = "The GuardDuty Detector ID in the Management account (ap-south-1)"
  value       = module.guardduty_aps1.management_detector_id
}

output "guardduty_aps1_audit_detector_id" {
  description = "The GuardDuty Detector ID in the Audit account (ap-south-1)"
  value       = module.guardduty_aps1.audit_detector_id
}
