variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "terraform-profile" {
  description = "AWS CLI profile for the Management account"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive critical security alerts"
  type        = string
}

variable "allowed_regions" {
  description = "Map of primary and secondary regions"
  type        = map(string)
  default = {
    primary   = "us-east-1"
    secondary = "ap-south-1"
  }
}
variable "state_bucket" {
  description = "S3 bucket holding all layer state files (from 00-bootstrap output state_bucket_name)"
  type        = string
}

variable "state_bucket_region" {
  description = "Region of the Terraform state bucket (must match 00-bootstrap var.aws_region)"
  type        = string
  default     = "us-east-1"
}
