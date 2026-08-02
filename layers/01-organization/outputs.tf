output "ou_ids" {
  description = "A map of OU names to their corresponding IDs"

  # This loops through all created modules and builds a map: { "Security" = "ou-1234", ... }
  value = { for name, ou in module.org_units : name => ou.ou_id }
}

output "account_ids" {
  description = "A map of Account names to their corresponding IDs"
  value       = { for name, acc in module.accounts : name => acc.account_id }
}

output "scp_ids" {
  description = "Map of SCP names to their policy IDs"
  value = {
    deny_root_user          = module.scp_deny_root_user.policy_id
    deny_leave_org          = module.scp_deny_leave_org.policy_id
    deny_disable_cloudtrail = module.scp_deny_disable_cloudtrail.policy_id
    deny_disable_config     = module.scp_deny_disable_config.policy_id
    deny_disable_guardduty  = module.scp_deny_disable_guardduty.policy_id
    restrict_regions        = module.scp_restrict_regions.policy_id
    protect_log_archive     = module.scp_protect_log_archive.policy_id
    deny_expensive_services = module.scp_deny_expensive_services.policy_id
    deny_network_bridging   = module.scp_deny_network_bridging.policy_id
    deny_iam_user_creation  = module.scp_deny_iam_user_creation.policy_id
  }
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
