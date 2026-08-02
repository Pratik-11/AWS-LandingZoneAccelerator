variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "org_id" {
  description = "AWS Organization ID (o-xxxxxxxxxx). Scopes the bucket policy so only principals in this org can write."
  type        = string
}

variable "service_type" {
  description = "Which log producer this bucket serves. Selects the bucket policy."
  type        = string

  validation {
    condition     = contains(["cloudtrail", "config", "flow-logs"], var.service_type)
    error_message = "service_type must be one of: cloudtrail, config, flow-logs."
  }
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key for SSE-KMS. Leave null for SSE-S3 (AES256)."
  type        = string
  default     = null
}
