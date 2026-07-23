variable "aws_region" {
  description = "The AWS region where bootstrap resources (S3, DynamoDB) will be created"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS CLI profile to use — must have management account privileges"
  type        = string
  default     = null
}

variable "org_name" {
  description = "Short slug for your organization, used as a prefix in resource names (e.g. 'acme')"
  type        = string
  default     = "acme"
}

variable "github_org" {
  description = "The GitHub organization name that is allowed to assume the OIDC role (e.g. 'my-org')"
  type        = string
  default     = "my-org"
}

variable "github_repo" {
  description = "The GitHub repository name allowed to assume the OIDC role (e.g. 'aws-landing-zone'). Use '*' to allow all repos in the org."
  type        = string
  default     = "*"
}

variable "unique_id" {
  description = "A short unique suffix appended to S3 bucket and DynamoDB table names to ensure global uniqueness (e.g. account ID last 4 digits, random string). Leave empty to omit."
  type        = string
}
