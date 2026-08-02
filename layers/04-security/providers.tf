terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "lz/01-organization/terraform.tfstate"
    region = var.state_bucket_region
  }
}

locals {
  audit_account_id = data.terraform_remote_state.org.outputs.account_ids["Audit"]
  all_account_ids  = values(data.terraform_remote_state.org.outputs.account_ids)

  # Applied automatically to every taggable resource created by this layer.
  default_tags = {
    ManagedBy = "terraform"
    Layer     = "04-security"
  }
}

# 1. Management Account (Default Provider -> for enabling org services + delegation)
provider "aws" {
  region  = var.aws_region
  profile = var.terraform-profile
  default_tags { tags = local.default_tags }
}

# ──────────────────────────────────────────────
# us-east-1 Providers
# ──────────────────────────────────────────────

# Alias — management explicit (for clarity in resources)
provider "aws" {
  alias   = "management_use1"
  region  = var.allowed_regions.primary
  profile = var.terraform-profile
  default_tags { tags = local.default_tags }
}

# Audit Account (Delegated Admin Provider -> for configuring delegated services)
provider "aws" {
  alias   = "audit_use1"
  region  = var.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.audit_account_id}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

