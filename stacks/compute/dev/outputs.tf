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

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name for compute resources"
  value       = module.ec2_instance_role.instance_profile_name
}

output "ec2_instance_profile_arn" {
  description = "EC2 instance profile ARN for compute resources"
  value       = module.ec2_instance_role.instance_profile_arn
}

output "ec2_role_name" {
  description = "EC2 IAM role name"
  value       = module.ec2_instance_role.role_name
}

output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = module.ec2_instance_role.role_arn
}

output "private_ec2_instance_id" {
  description = "Private EC2 instance ID"
  value       = module.private_ec2.instance_id
}

output "private_ec2_instance_arn" {
  description = "Private EC2 instance ARN"
  value       = module.private_ec2.instance_arn
}

output "private_ec2_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = module.private_ec2.private_ip
}

output "private_ec2_instance_name" {
  description = "Private EC2 instance name"
  value       = module.private_ec2.instance_name
}
