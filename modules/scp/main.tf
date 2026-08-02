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

variable "name" {
  description = "Name of the SCP"
  type        = string
}

variable "description" {
  description = "Description of the SCP"
  type        = string
  default     = ""
}

variable "policy_json" {
  description = "The SCP policy document as a JSON string"
  type        = string
}

variable "target_ids" {
  description = "List of OU IDs or Account IDs to attach this SCP to"
  type        = list(string)

  validation {
    condition     = length(var.target_ids) > 0
    error_message = "An SCP with no targets does nothing — pass at least one OU or account ID."
  }
}

output "policy_id" {
  description = "The ID of the created SCP"
  value       = aws_organizations_policy.this.id
}

output "policy_arn" {
  description = "The ARN of the created SCP"
  value       = aws_organizations_policy.this.arn
}
