terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Reads the outputs published by the 01-organization layer.
# Every layer after 01 consumes account IDs this way — it is the only coupling
# between layers, and it is read-only.
data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "lz/01-organization/terraform.tfstate"
    region = var.state_bucket_region
  }
}

locals {
  allowed_regions        = data.terraform_remote_state.org.outputs.allowed_regions
  org_id                 = data.terraform_remote_state.org.outputs.org_id
  management_account_id  = data.terraform_remote_state.org.outputs.management_account_id
  audit_account_id       = data.terraform_remote_state.org.outputs.account_ids["Audit"]
  log_archive_account_id = data.terraform_remote_state.org.outputs.account_ids["LogArchive"]

  # Applied automatically to every taggable resource created by this layer.
  default_tags = {
    ManagedBy = "terraform"
    Layer     = "02-logging"
  }
}

# Default provider — management account. The organization trail must be created
# from here; only the management account may set is_organization_trail.
provider "aws" {
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  default_tags { tags = local.default_tags }
}

# LogArchive account, via assume-role. All buckets and the CMK land here.
provider "aws" {
  alias   = "log_archive"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile

  assume_role {
    role_arn = "arn:aws:iam::${local.log_archive_account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}
