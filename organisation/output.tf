output "ou_ids" {
  description = "A map of OU names to their corresponding IDs"
  
  # This loops through all created modules and builds a map: { "Security" = "ou-1234", ... }
  value = { for name, ou in module.org_units : name => ou.ou_id }
}

output "account_ids" {
  description = "A map of Account names to their corresponding IDs"
  value       = { for name, acc in module.accounts : name => acc.account_id }
}