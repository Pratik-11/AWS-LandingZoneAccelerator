terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
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
  network_account  = data.terraform_remote_state.org.outputs.account_ids["Network"]
  dev_account      = data.terraform_remote_state.org.outputs.account_ids["Dev"]
  prod_account     = data.terraform_remote_state.org.outputs.account_ids["Prod"]
  shared_account   = data.terraform_remote_state.org.outputs.account_ids["SharedServices"]
  sandbox_account  = data.terraform_remote_state.org.outputs.account_ids["Sandbox"]
  log_archive_acct = data.terraform_remote_state.org.outputs.account_ids["LogArchive"]
  allowed_regions  = data.terraform_remote_state.org.outputs.allowed_regions
}

# ──────────────────────────────────────────────
# US-EAST-1 PROVIDERS
# ──────────────────────────────────────────────
provider "aws" {
  alias   = "network_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.network_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "dev_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.dev_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "prod_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.prod_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "shared_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.shared_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "sandbox_use1"
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.sandbox_account}:role/OrganizationAccountAccessRole"
  }
}

# ──────────────────────────────────────────────
# AP-SOUTH-1 PROVIDERS
# ──────────────────────────────────────────────
provider "aws" {
  alias   = "network_aps1"
  region  = local.allowed_regions.secondary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.network_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "dev_aps1"
  region  = local.allowed_regions.secondary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.dev_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "prod_aps1"
  region  = local.allowed_regions.secondary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.prod_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "shared_aps1"
  region  = local.allowed_regions.secondary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.shared_account}:role/OrganizationAccountAccessRole"
  }
}
provider "aws" {
  alias   = "sandbox_aps1"
  region  = local.allowed_regions.secondary
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.sandbox_account}:role/OrganizationAccountAccessRole"
  }
}