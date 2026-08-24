variable "name" {
  description = "Project or organization"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer target group"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID monitored by the alarms"
  type        = string
}

variable "tags" {
  description = "Additional tags applied to observability resources"
  type        = map(string)
  default     = {}
}
