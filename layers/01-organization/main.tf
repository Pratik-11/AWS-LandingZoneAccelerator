resource "aws_organizations_organization" "org" {
  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  # Services allowed to operate across the whole org. A service missing from
  # this list cannot be delegated to Audit in 04-security.
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "inspector2.amazonaws.com"
  ]
}

# Lets 05-network share the Transit Gateway across the org via RAM.
resource "aws_ram_sharing_with_organization" "org_sharing" {
  provider = aws
}

# OUs and accounts are plain resources, not modules. Both wrap exactly one AWS
# resource with no added logic, and for_each does the work a module would have.
# A module earns its keep when it bundles several resources — see modules/vpc.
resource "aws_organizations_organizational_unit" "this" {
  for_each = var.ou_names

  name      = each.value
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name      = each.key
  email     = each.value.email
  parent_id = aws_organizations_organizational_unit.this[each.value.ou_name].id

  # AWS cannot delete accounts via the API. Destroying this resource only
  # removes it from state — closure is a manual, rate-limited console action.
  close_on_deletion = false
}
