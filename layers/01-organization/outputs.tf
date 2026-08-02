output "account_ids" {
  description = "Map of account name to account ID. Read by layers 02–06."
  value       = { for name, acc in aws_organizations_account.this : name => acc.id }
}

output "management_account_id" {
  description = "Account ID of the management (payer) account this layer runs in"
  value       = aws_organizations_organization.org.master_account_id
}

output "org_id" {
  description = "The AWS Organization ID (o-xxxxxxxxxx)"
  value       = aws_organizations_organization.org.id
}

output "ou_ids" {
  description = "Map of OU name to OU ID"
  value       = { for name, ou in aws_organizations_organizational_unit.this : name => ou.id }
}

output "allowed_regions" {
  description = "Regions permitted org-wide. Read by layers 02–06 to pick a region."
  value       = var.allowed_regions
}
