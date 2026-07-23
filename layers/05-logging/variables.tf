variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cloudtrail_bucket_name" {
  type = string
}

variable "config_bucket_name" {
  type = string
}

variable "terraform-profile" {
  description = "The AWS CLI profile to use for Terraform execution"
  type        = string
}