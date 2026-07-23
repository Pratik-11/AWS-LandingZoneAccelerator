terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

data "terraform_remote_state" "org" {
  backend = "local"
  config  = { path = "../organisation/terraform.tfstate" }
}

locals {
  management_account_id    = data.terraform_remote_state.org.outputs.management_account_id
  audit_account_id         = data.terraform_remote_state.org.outputs.account_ids["Audit"]
  log_archive_account_id   = data.terraform_remote_state.org.outputs.account_ids["LogArchive"]
  network_account_id       = data.terraform_remote_state.org.outputs.account_ids["Network"]
  shared_services_account_id = data.terraform_remote_state.org.outputs.account_ids["SharedServices"]
  dev_account_id           = data.terraform_remote_state.org.outputs.account_ids["Dev"]
  prod_account_id          = data.terraform_remote_state.org.outputs.account_ids["Prod"]
  sandbox_account_id       = data.terraform_remote_state.org.outputs.account_ids["Sandbox"]
}

provider "aws" {
  region  = "us-east-1"
  profile = var.terraform-profile
}