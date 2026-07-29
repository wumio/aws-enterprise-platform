variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ca-central-1"
}

variable "company_name" {
  description = "Organization identifier"
  type        = string
  default     = "nhs"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "bootstrap"
}
