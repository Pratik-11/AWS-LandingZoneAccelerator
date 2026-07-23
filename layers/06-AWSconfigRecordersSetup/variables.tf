variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "terraform-profile" {
  description = "The AWS CLI profile to use for Terraform execution"
  type        = string
}