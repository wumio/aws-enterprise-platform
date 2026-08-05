output "vpc_id" {
  description = "VPC ID used by the security foundation"
  value       = data.terraform_remote_state.networking.outputs.vpc_id
}

output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = module.flow_logs.flow_log_id
}

output "flow_log_group_name" {
  description = "Cloudwatch Log Group containing VPC Flow Logs"
  value       = module.flow_logs.log_group_name
}

output "alb_security_group_id" {
  description = "Security group ID for the application load balancer"
  value       = module.security_groups.alb_security_group_id
}

output "application_security_group_id" {
  description = "Security group ID for application workloads"
  value       = module.security_groups.application_security_group_id
}

output "database_security_group_id" {
  description = "Security group ID for database workloads"
  value       = module.security_groups.database_security_group_id
}
