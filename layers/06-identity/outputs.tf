output "sso_instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = local.sso_instance_arn
}

output "identity_store_id" {
  description = "IAM Identity Center identity store ID"
  value       = local.sso_identity_store_id
}

output "permission_set_arns" {
  description = "Map of permission set names to their ARNs"
  value = {
    power          = aws_ssoadmin_permission_set.power.arn
    read_only      = aws_ssoadmin_permission_set.read_only.arn
    developer      = aws_ssoadmin_permission_set.developer.arn
    security_audit = aws_ssoadmin_permission_set.security_audit.arn
    billing        = aws_ssoadmin_permission_set.billing.arn
  }
}

output "group_ids" {
  description = "Map of group names to their IDs"
  value = {
    platform_engineers = aws_identitystore_group.platform_engineers.group_id
    developers         = aws_identitystore_group.developers.group_id
    security_team      = aws_identitystore_group.security_team.group_id
    finance            = aws_identitystore_group.finance.group_id
  }
}

output "user_ids" {
  description = "Map of usernames to their IAM IC user IDs"
  value       = { for username, user in aws_identitystore_user.users : username => user.user_id }
}