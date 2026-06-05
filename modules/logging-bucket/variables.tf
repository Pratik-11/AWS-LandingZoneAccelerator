variable "bucket_name" {
  type = string
}

variable "org_id" {
  description = "The AWS Organization ID (e.g., o-xxxxxxx) to restrict bucket access"
  type        = string
}

variable "service_type" {
  description = "Must be either 'cloudtrail' or 'config'"
  type        = string
}