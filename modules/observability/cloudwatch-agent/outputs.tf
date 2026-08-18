output "nginx_log_group_name" {
  description = "CloudWatch Log Group receiving nginx logs"
  value       = aws_cloudwatch_log_group.nginx.name
}

output "nginx_log_group_arn" {
  description = "ARN of the CloudWatch Log Group receiving nginx logs"
  value       = aws_cloudwatch_log_group.nginx.arn
}
