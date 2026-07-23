
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