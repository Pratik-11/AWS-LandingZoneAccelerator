variable "cidr" {
  description = "VPC CIDR block"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid IPv4 CIDR block, e.g. 10.1.0.0/16."
  }
}

variable "public_subnets" {
  description = "Public subnet CIDRs. Must be empty when create_public_subnets is false."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.public_subnets : can(cidrhost(c, 0))])
    error_message = "Every public_subnets entry must be a valid IPv4 CIDR block."
  }
}

variable "private_subnets" {
  description = "Private subnet CIDRs. At least one is required."
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) > 0
    error_message = "At least one private subnet is required — TGW attachments live in private subnets."
  }

  validation {
    condition     = alltrue([for c in var.private_subnets : can(cidrhost(c, 0))])
    error_message = "Every private_subnets entry must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  description = <<-EOT
    Availability zones, one per subnet index.

    These are AZ *names* (us-east-1a). AWS maps names to physical datacentres
    differently in every account, so us-east-1a in Dev is probably not the same
    building as us-east-1a in Prod. If placement matters, switch to AZ IDs.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "At least one availability zone is required."
  }
}

variable "create_public_subnets" {
  description = "false gives a fully private VPC — no IGW, no NAT, no public subnets. Used for Prod."
  type        = bool
  default     = true
}

variable "flow_logs_destination_arn" {
  description = "S3 bucket ARN to deliver VPC flow logs to. Null disables flow logs."
  type        = string
  default     = null
}
