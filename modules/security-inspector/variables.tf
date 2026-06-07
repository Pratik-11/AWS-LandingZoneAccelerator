variable "audit_account_id" {
  description = "The AWS Account ID of the Audit account"
  type        = string
}

variable "all_account_ids" {
  description = "List of all AWS Account IDs in the organization (including Audit)"
  type        = list(string)
}