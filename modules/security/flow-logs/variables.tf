variable "name" {
  description = "Organization or project name"
  type        = string
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where flow logs will be enabled"
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain VPC flow logs in CloudWatch Logs"
  type        = number
  default     = 365
}
