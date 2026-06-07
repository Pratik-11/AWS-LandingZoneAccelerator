terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "terraform_remote_state" "org" {
  backend = "local"
  config = {
    path = "../organisation/terraform.tfstate"
  }
}

locals {
  audit_account_id = data.terraform_remote_state.org.outputs.account_ids["Audit"]
  allowed_regions  = data.terraform_remote_state.org.outputs.allowed_regions
  all_account_ids  = values(data.terraform_remote_state.org.outputs.account_ids)
}

# 1. Management Account (Default Provider -> for enabling org services + delegation)
provider "aws" {
  region  = var.aws_region
  profile = var.terraform-profile
}


# ──────────────────────────────────────────────
# us-east-1 Providers
# ──────────────────────────────────────────────

# Alias — management explicit (for clarity in resources)
provider "aws" {
  alias   = "management_use1"
  region  = local.allowed_regions[0] 
  profile = var.terraform-profile
}

# Audit Account (Delegated Admin Provider -> for configuring delegated services)
provider "aws" {
  alias   = "audit_use1"
  region  = local.allowed_regions[0]
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.audit_account_id}:role/OrganizationAccountAccessRole"
  }
}

# ──────────────────────────────────────────────
# ap-south-1 Providers
# ──────────────────────────────────────────────
provider "aws" {
  alias   = "management_aps1"
  region  = local.allowed_regions[1]
  profile = var.terraform-profile
}

provider "aws" {
  alias   = "audit_aps1"
  region  = local.allowed_regions[1]
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.audit_account_id}:role/OrganizationAccountAccessRole"
  }
}