output "cloudtrail_bucket_id" {
  description = "The name/ID of the CloudTrail logs S3 bucket"
  value       = module.cloudtrail_bucket.bucket_id
}

output "config_bucket_id" {
  description = "The name/ID of the AWS Config logs S3 bucket"
  value       = module.config_bucket.bucket_id
}