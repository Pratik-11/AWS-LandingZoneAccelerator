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
}

variable "landing_zone_type" {
  description = "The Landing Zone persona. Controls which set of SCPs is enforced."
  type        = string
  default     = "enterprise"
  validation {
    condition     = contains(["startup", "enterprise", "regulated"], var.landing_zone_type)
    error_message = "landing_zone_type must be startup, enterprise, or regulated."
  }
}