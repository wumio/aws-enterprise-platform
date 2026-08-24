output "sns_topic_arn" {
  description = "ARN of the observability alerts SNS topic"
  value       = aws_sns_topic.alerts.arn
}

output "alarm_arns" {
  description = "ARNs of the observability CloudWatch alarms"
  value = {
    alb_unhealthy_targets = aws_cloudwatch_metric_alarm.alb_unhealthy_targets.arn
    alb_target_5xx        = aws_cloudwatch_metric_alarm.alb_target_5xx.arn
    ec2_status_check      = aws_cloudwatch_metric_alarm.ec2_status_check.arn
  }
}
