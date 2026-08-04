variable "name" {
  description = "Organization name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
}
