resource "aws_organizations_organization" "org" {
  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  # Enable org wide services
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "inspector2.amazonaws.com"
  ]
}

module "org_units" {
  source   = "../modules/ou"
  for_each = var.ou_names

  # each.value represents the current string in the loop (e.g. "Security")
  name      = each.value
  parent_id = aws_organizations_organization.org.roots[0].id
}

module "accounts" {
  source   = "../modules/accounts"
  for_each = var.accounts

  name      = each.key
  email     = each.value.email
  parent_id = module.org_units[each.value.ou_name].ou_id
}