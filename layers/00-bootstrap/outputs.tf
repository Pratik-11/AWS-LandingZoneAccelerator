output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role that GitHub Actions pipelines can assume via OIDC"
  value       = aws_iam_role.github_actions_oidc.arn
}
