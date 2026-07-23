output "policy_id" {
  description = "The ID of the created SCP, or null if skipped by persona toggle"
  value       = length(aws_organizations_policy.this) > 0 ? aws_organizations_policy.this[0].id : null
}

output "policy_arn" {
  description = "The ARN of the created SCP, or null if skipped by persona toggle"
  value       = length(aws_organizations_policy.this) > 0 ? aws_organizations_policy.this[0].arn : null
}