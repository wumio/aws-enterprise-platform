output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.vpc.id
}

output "log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}
