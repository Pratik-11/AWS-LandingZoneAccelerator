variable "config_logs_bucket_name" {
  description = "The name of the central S3 bucket in the LogArchive account"
  type        = string
}

variable "config_logs_bucket_arn" {
  description = "The ARN of the central S3 bucket in the LogArchive account"
  type        = string
}

variable "create_iam_role" {
  description = "Whether to create the IAM role. Set to false for the second region in the same account (IAM is global)."
  type        = bool
  default     = true
}