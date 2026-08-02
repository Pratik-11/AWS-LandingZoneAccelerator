output "config_bucket_id" {
  description = "The name/ID of the AWS Config logs S3 bucket"
  value       = module.config_bucket.bucket_id
}

output "config_bucket_arn" {
  description = "The ARN of the AWS Config logs S3 bucket"
  value       = module.config_bucket.bucket_arn
}

output "flow_logs_bucket_arn" {
  description = "ARN of the VPC flow logs bucket — consumed by 05-network"
  value       = module.flow_logs_bucket.bucket_arn
}

