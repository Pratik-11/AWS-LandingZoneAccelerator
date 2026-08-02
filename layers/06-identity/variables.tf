variable "terraform-profile" {
  description = "AWS CLI profile for the management account"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all taggable resources"
  type        = map(string)
  default = {
    Project   = "LandingZone"
    Phase     = "Identity"
    ManagedBy = "Terraform"
  }
}

variable "sso_users" {
  description = "Map of SSO users to create in the built-in directory"
  type = map(object({
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
    groups       = list(string)
  }))
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
