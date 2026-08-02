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

  # default_tags stamps every taggable resource this provider creates. It is the
  # idiomatic way to do baseline tagging — far better than merging a map into
  # every resource by hand and forgetting one.
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Layer     = "00-bootstrap"
    }
  }
}
