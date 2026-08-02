output "ou_ids" {
  description = "A map of OU names to their corresponding IDs"

  # This loops through all created modules and builds a map: { "Security" = "ou-1234", ... }
  value = { for name, ou in aws_organizations_organizational_unit.this : name => ou.id }
}

output "account_ids" {
  description = "A map of Account names to their corresponding IDs"
  value       = { for name, acc in aws_organizations_account.this : name => acc.id }
}

output "org_id" {
  description = "The AWS Organization ID"
  value       = aws_organizations_organization.org.id
}

output "allowed_regions" {
  description = "Map of primary and secondary regions permitted across the organization"
  value       = var.allowed_regions
}
output "management_account_id" {
  description = "Account ID of the management (payer) account this layer runs in"
  value       = aws_organizations_organization.org.master_account_id
}
