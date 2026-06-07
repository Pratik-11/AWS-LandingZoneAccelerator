output "management_hub_arn" {
  value = aws_securityhub_account.management.arn
}

output "audit_hub_arn" {
  value = aws_securityhub_account.audit.arn
}