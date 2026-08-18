variable "name" {
  description = "Project or organization name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "retention_in_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags applied to observability resources"
  type        = map(string)
  default     = {}
}
