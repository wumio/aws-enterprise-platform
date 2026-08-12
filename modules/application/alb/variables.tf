variable "name" {
  description = "Project or organization name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "The ALB requires at least two subnets."
  }
}

variable "security_group_id" {
  description = "Security group ID assigned to the ALB"
  type        = string
}

variable "target_instance_id" {
  description = "EC2 instance ID registered with the target group"
  type        = string
}

variable "target_port" {
  description = "Port exposed by the application workload"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used for target health checks"
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "Additional tags applied to application resources"
  type        = map(string)
  default     = {}
}
