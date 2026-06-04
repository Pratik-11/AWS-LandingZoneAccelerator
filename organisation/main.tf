resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
}

module "security_ou" {
  source = "../modules/ou"

  name      = var.security_ou_name
  parent_id = aws_organizations_organization.org.roots[0].id
}

module "infra_ou" {
  source = "../modules/ou"

  name      = var.infra_ou_name
  parent_id = aws_organizations_organization.org.roots[0].id
}

module "sandbox_ou" {
  source = "../modules/ou"

  name      = var.sandbox_ou_name
  parent_id = aws_organizations_organization.org.roots[0].id
}

module "workloads_ou" {
  source = "../modules/ou"

  name      = var.workloads_ou_name
  parent_id = aws_organizations_organization.org.roots[0].id
}