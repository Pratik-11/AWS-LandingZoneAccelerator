terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider (runs in the Management Account)
provider "aws" {
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
}

# Data source to read outputs from the organisation module
data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "lz/01-organization/terraform.tfstate"
    region = var.state_bucket_region
  }
}

locals {
  allowed_regions = data.terraform_remote_state.org.outputs.allowed_regions
}

# Log Archive provider (runs inside the LogArchive account via AssumeRole)
provider "aws" {
  alias   = "log_archive"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile

  assume_role {
    # Dynamically fetch the LogArchive account ID from the remote state
    role_arn = "arn:aws:iam::${data.terraform_remote_state.org.outputs.account_ids["LogArchive"]}:role/OrganizationAccountAccessRole"
  }
}