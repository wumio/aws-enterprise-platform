output "vpc_id" {
  description = "VPC ID consumed from the networking stack"
  value       = data.terraform_remote_state.networking.outputs.vpc_id
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs consumed from the networking stack"
  value       = data.terraform_remote_state.networking.outputs.private_app_subnet_ids
}

output "application_security_group_id" {
  description = "Application security group ID consumed from the security stack"
  value       = data.terraform_remote_state.security.outputs.application_security_group_id
}

output "alb_security_group_id" {
  description = "Application load balancer security group ID consumed from the security stack"
  value       = data.terraform_remote_state.security.outputs.alb_security_group_id
}
