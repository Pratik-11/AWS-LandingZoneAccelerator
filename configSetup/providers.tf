terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ──────────────────────────────────────────────
# Remote State References
# ──────────────────────────────────────────────

data "terraform_remote_state" "org" {
  backend = "local"
  config = {
    path = "../organisation/terraform.tfstate"
  }
}

data "terraform_remote_state" "logging" {
  backend = "local"
  config = {
    path = "../logging/terraform.tfstate"
  }
}

# ──────────────────────────────────────────────
# Local values for cleaner references
# ──────────────────────────────────────────────

locals {
  account_ids        = data.terraform_remote_state.org.outputs.account_ids
  config_bucket_id   = data.terraform_remote_state.logging.outputs.config_bucket_id
  config_bucket_arn  = data.terraform_remote_state.logging.outputs.config_bucket_arn  
}

# ──────────────────────────────────────────────
# Default Provider (Management Account)
# ──────────────────────────────────────────────

provider "aws" {
  region  = var.aws_region
  profile = var.terraform-profile
}

# ──────────────────────────────────────────────
# Provider Aliases for Each Member Account
# ──────────────────────────────────────────────

provider "aws" {
  alias   = "dev"
  region  = var.aws_region
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Dev"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "prod"
  region  = var.aws_region
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Prod"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "audit"
  region  = var.aws_region
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Audit"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "log_archive"
  region  = var.aws_region
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["LogArchive"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "network"
  region  = var.aws_region
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Network"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "shared_services"
  region  = var.aws_region
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["SharedServices"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "sandbox"
  region  = var.aws_region
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Sandbox"]}:role/OrganizationAccountAccessRole"
  }
}