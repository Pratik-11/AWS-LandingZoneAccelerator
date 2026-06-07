# ──────────────────────────────────────────────────────────────────
# Security Hub — Central Configuration
# Manages the delegation policy + org config policy created via console.
# These were initially bootstrapped via console due to IAM race conditions
# on first-time setup. Imported into state post-console-setup.
# ──────────────────────────────────────────────────────────────────

# The Central Configuration policy applied to the org Root.
# Enables Security Hub + AWS Foundational Security Best Practices v1.0.0
# across all accounts in the organization.
resource "aws_securityhub_configuration_policy" "org_policy" {
  provider = aws.audit_use1
  name     = "configuration-policy-01"  # match exactly

  configuration_policy {
    service_enabled = true
    enabled_standard_arns = [
      "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
    ]
    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }
}

# Associates the configuration policy with the org Root,
# so it applies to all OUs and all accounts.
resource "aws_securityhub_configuration_policy_association" "root" {
  provider  = aws.audit_use1
  target_id = "r-kinq"  
  policy_id = aws_securityhub_configuration_policy.org_policy.id
}