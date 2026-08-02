variable "aws_region" {
  type = string
}

variable "terraform-profile" {
  type = string
}

# Define a single variable that holds all desired OU names
variable "ou_names" {
  description = "A set of Organizational Unit names to be created under the root"
  type        = set(string)
  default = [
    "Security",
    "Infrastructure",
    "Sandbox",
    "Workloads"
  ]
}

variable "accounts" {
  description = "A map of accounts to be created, specifying their email and the parent OU name."
  type = map(object({
    email   = string
    ou_name = string
  }))
}

variable "allowed_regions" {
  description = "Map of primary and secondary regions"
  type        = map(string)
  default = {
    primary   = "us-east-1"
    secondary = "ap-south-1"
  }
}