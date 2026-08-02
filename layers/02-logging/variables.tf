
variable "cloudtrail_bucket_name" {
  type = string
}

variable "config_bucket_name" {
  type = string
}

variable "flow_logs_bucket_name" {
  description = "Globally unique name for the VPC flow logs bucket in LogArchive"
  type        = string
}

variable "terraform-profile" {
  description = "The AWS CLI profile to use for Terraform execution"
  type        = string
}
# ──────────────────────────────────────────────────────────────────────────────
# Remote state lookup — where this layer reads upstream layer outputs from.
# Same bucket/region you put in backend.s3.tfbackend. Get them with:
#   cd layers/00-bootstrap && terraform output
# ──────────────────────────────────────────────────────────────────────────────

variable "state_bucket" {
  description = "S3 bucket holding all layer state files (from 00-bootstrap output state_bucket_name)"
  type        = string
}

variable "state_bucket_region" {
  description = "Region of the Terraform state bucket (must match 00-bootstrap var.aws_region)"
  type        = string
  default     = "us-east-1"
}
