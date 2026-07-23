# STEP 1: Delegate Config Admin
resource "aws_organizations_delegated_administrator" "config_admin" {
  account_id        = local.audit_account_id
  service_principal = "config.amazonaws.com"
}

# STEP 2: IAM Role for the Aggregator in the Audit account
resource "aws_iam_role" "config_aggregator_role_audit" {
  provider           = aws.audit_use1
  name               = "AWSConfigAggregatorRoleAudit"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aggregator_policy_audit" {
  provider   = aws.audit_use1
  role       = aws_iam_role.config_aggregator_role_audit.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

# STEP 3: Create the Aggregator in the Audit account
resource "aws_config_configuration_aggregator" "audit_aggregator" {
  provider = aws.audit_use1
  name     = "organization-audit-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator_role_audit.arn
  }

  depends_on = [
    aws_organizations_delegated_administrator.config_admin,
    aws_iam_role_policy_attachment.aggregator_policy_audit
  ]
}