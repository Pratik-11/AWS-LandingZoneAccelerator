output "config_role_arn" {
  description = "ARN of the Config Recorder IAM Role"
  value       = var.create_iam_role ? aws_iam_role.config_role[0].arn : var.existing_role_arn
}