variable "terraform-profile" { type = string }
variable "state_bucket" {
  description = "S3 bucket holding all layer state files (from 00-bootstrap output state_bucket_name)"
  type        = string
}

variable "state_bucket_region" {
  description = "Region of the Terraform state bucket (must match 00-bootstrap var.aws_region)"
  type        = string
  default     = "us-east-1"
}
