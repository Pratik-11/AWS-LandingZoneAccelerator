terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# Runs as the management account — no assume_role required.
# The profile passed here must have org-admin privileges.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
