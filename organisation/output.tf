output "ou_ids" {
  description = "A map of OU names to their corresponding IDs"
  
  # This loops through all created modules and builds a map: { "Security" = "ou-1234", ... }
  value = { for name, ou in module.org_units : name => ou.ou_id }
}

output "network_account_id" {
  value = module.network_account.account_id
}

output "shared_services_account_id" {
  value = module.shared_services_account.account_id
}

output "audit_account_id" {
  value = module.audit_account.account_id
}

output "log_archive_account_id" {
  value = module.log_archive_account.account_id
}

output "sandbox_account_id" {
  value = module.sandbox_account.account_id
}

output "dev_account_id" {
  value = module.dev_account.account_id
}

output "prod_account_id" {
  value = module.prod_account.account_id
}