variable "aws_region" {
  type = string
}

variable "name" {
  description = "Project or organization name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}
