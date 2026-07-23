terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

data "terraform_remote_state" "org" {
  backend = "local"
  config  = { path = "../../layers/01-organization/terraform.tfstate" }
}

locals {
  management_account_id      = data.terraform_remote_state.org.outputs.management_account_id
  audit_account_id           = data.terraform_remote_state.org.outputs.account_ids["Audit"]
  log_archive_account_id     = data.terraform_remote_state.org.outputs.account_ids["LogArchive"]
  network_account_id         = data.terraform_remote_state.org.outputs.account_ids["Network"]
  shared_services_account_id = data.terraform_remote_state.org.outputs.account_ids["SharedServices"]
  dev_account_id             = data.terraform_remote_state.org.outputs.account_ids["Dev"]
  prod_account_id            = data.terraform_remote_state.org.outputs.account_ids["Prod"]
  sandbox_account_id         = data.terraform_remote_state.org.outputs.account_ids["Sandbox"]
  # Region map from org layer — IAM Identity Center API calls use the primary region
  allowed_regions            = data.terraform_remote_state.org.outputs.allowed_regions
}

provider "aws" {
  # IAM Identity Center is global but the API endpoint is region-scoped to the primary region
  region  = local.allowed_regions.primary
  profile = var.terraform-profile
}