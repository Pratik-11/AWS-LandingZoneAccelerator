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