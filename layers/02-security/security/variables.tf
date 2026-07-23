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

variable "regions" {
  description = "Map of primary and secondary regions"
  type        = map(string)
  default = {
    primary   = "us-east-1"
    secondary = "ap-south-1"
  }
}