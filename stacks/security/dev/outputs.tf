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
