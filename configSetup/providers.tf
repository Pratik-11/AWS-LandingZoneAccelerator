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
  account_ids      = data.terraform_remote_state.org.outputs.account_ids
  allowed_regions  = data.terraform_remote_state.org.outputs.allowed_regions
  config_bucket_id = data.terraform_remote_state.logging.outputs.config_bucket_id
  config_bucket_arn = data.terraform_remote_state.logging.outputs.config_bucket_arn
}

# ──────────────────────────────────────────────
# Default Provider (Management Account, primary region)
# ──────────────────────────────────────────────

provider "aws" {
  region  = var.aws_region
  profile = var.terraform-profile
}

# ──────────────────────────────────────────────
# us-east-1 Provider Aliases (already existing, one per account)
# ──────────────────────────────────────────────

provider "aws" {
  alias   = "dev_use1"
  region  = "us-east-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Dev"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "prod_use1"
  region  = "us-east-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Prod"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "audit_use1"
  region  = "us-east-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Audit"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "log_archive_use1"
  region  = "us-east-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["LogArchive"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "network_use1"
  region  = "us-east-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Network"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "shared_services_use1"
  region  = "us-east-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["SharedServices"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "sandbox_use1"
  region  = "us-east-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Sandbox"]}:role/OrganizationAccountAccessRole"
  }
}

# ──────────────────────────────────────────────
# ap-south-1 Provider Aliases (NEW, one per account)
# ──────────────────────────────────────────────

provider "aws" {
  alias   = "dev_aps1"
  region  = "ap-south-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Dev"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "prod_aps1"
  region  = "ap-south-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Prod"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "audit_aps1"
  region  = "ap-south-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Audit"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "log_archive_aps1"
  region  = "ap-south-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["LogArchive"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "network_aps1"
  region  = "ap-south-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Network"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "shared_services_aps1"
  region  = "ap-south-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["SharedServices"]}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias   = "sandbox_aps1"
  region  = "ap-south-1"
  profile = var.terraform-profile
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["Sandbox"]}:role/OrganizationAccountAccessRole"
  }
}