terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ──────────────────────────────────────────────
# Remote state — account IDs from 01, Config bucket from 02
# ──────────────────────────────────────────────

data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "lz/01-organization/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "terraform_remote_state" "logging" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "lz/02-logging/terraform.tfstate"
    region = var.state_bucket_region
  }
}

locals {
  account_ids       = data.terraform_remote_state.org.outputs.account_ids
  allowed_regions   = data.terraform_remote_state.org.outputs.allowed_regions
  config_bucket_id  = data.terraform_remote_state.logging.outputs.config_bucket_id
  config_bucket_arn = data.terraform_remote_state.logging.outputs.config_bucket_arn

  # Applied automatically to every taggable resource created by this layer.
  default_tags = {
    ManagedBy = "terraform"
    Layer     = "03-config-recorders"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# One provider per account. THIS is the file to read if you want to understand
# why multi-account Terraform is shaped the way it is: provider blocks accept no
# for_each and no count, so N accounts means N hand-written blocks. There is no
# way around it inside a single root module.
#
# docs/KNOWN-LIMITS.md §1 covers the three real options and when to switch.
# ──────────────────────────────────────────────────────────────────────────────

# Management account, primary region.
provider "aws" {
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias   = "dev_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Dev"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias   = "prod_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Prod"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias   = "audit_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Audit"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias   = "log_archive_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["LogArchive"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias   = "network_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Network"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias   = "shared_services_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["SharedServices"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias   = "sandbox_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Sandbox"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}

# Second region — only Dev, matching the single worked example in main.tf.
# Same account, different region, therefore a separate provider. Add one of
# these per account you want recorded in the secondary region.
provider "aws" {
  alias   = "dev_aps1"
  region  = local.allowed_regions.secondary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Dev"]}:role/OrganizationAccountAccessRole"
  }
  default_tags { tags = local.default_tags }
}
