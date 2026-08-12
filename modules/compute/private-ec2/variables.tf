variable "name" {
  description = "Project or organization name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID where the EC2 instance will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID assigned to the EC2 instance"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile attached to the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Additional tags applied to the EC2 instance and root volume"
  type        = map(string)
  default     = {}
}

variable "user_data" {
  description = "Optional user data script used to bootstrap the EC2 workload"
  type        = string
  default     = null
}
