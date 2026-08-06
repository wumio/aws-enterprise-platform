variable "name" {
  description = "Project or organization name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the SSM endpoint security group will be created"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets allowed to access SSM VPC endpoints"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Private subnet IDs where SSM interface endpoints will be deployed"
  type        = list(string)
}
