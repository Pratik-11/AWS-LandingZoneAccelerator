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
