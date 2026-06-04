resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
}

module "org_units" {
  source   = "../modules/ou"
  for_each = var.ou_names

  # each.value represents the current string in the loop (e.g. "Security")
  name      = each.value
  parent_id = aws_organizations_organization.org.roots[0].id
}

module "network_account" {
  source = "../modules/account"

  name      = "Network"
  email     = var.network_account_email

  parent_id = module.infra_ou.ou_id
}

module "shared_services_account" {
  source = "../modules/account"

  name      = "SharedServices"
  email     = var.shared_services_account_email

  parent_id = module.infra_ou.ou_id
}

module "audit_account" {
  source = "../modules/account"

  name      = "Audit"
  email     = var.audit_account_email

  parent_id = module.security_ou.ou_id
}

module "log_archive_account" {
  source = "../modules/account"

  name      = "LogArchive"
  email     = var.log_archive_account_email

  parent_id = module.security_ou.ou_id
}

module "sandbox_account" {
  source = "../modules/account"

  name      = "Sandbox"
  email     = var.sandbox_account_email

  parent_id = module.sandbox_ou.ou_id
}

module "dev_account" {
  source = "../modules/account"

  name      = "Dev"
  email     = var.dev_account_email

  parent_id = module.workloads_ou.ou_id
}

module "prod_account" {
  source = "../modules/account"

  name      = "Prod"
  email     = var.prod_account_email

  parent_id = module.workloads_ou.ou_id
}