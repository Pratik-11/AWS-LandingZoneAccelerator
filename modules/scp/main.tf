# Creates one Service Control Policy and attaches it to one or more targets.
#
# There is deliberately no on/off switch here. To drop a guardrail, delete or
# comment out its module block in layers/01-organization/scps.tf — the SCPs you
# get are exactly the module blocks you can see.

resource "aws_organizations_policy" "this" {
  name        = var.name
  description = var.description
  content     = var.policy_json
  type        = "SERVICE_CONTROL_POLICY"
}

# Attach to each target OU or account. Attaching to an OU rather than an account
# is the pattern to follow — accounts inherit from their OU, so moving an account
# between OUs changes its guardrails with no Terraform edit.
resource "aws_organizations_policy_attachment" "this" {
  for_each = toset(var.target_ids)

  policy_id = aws_organizations_policy.this.id
  target_id = each.value
}
