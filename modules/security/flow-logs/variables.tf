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
