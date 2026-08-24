output "alb_id" {
  description = "Application Load Balancer ID"
  value       = module.alb.load_balancer_id
}

output "alb_arn" {
  description = "Application load balancer ARN"
  value       = module.alb.load_balancer_arn
}

output "alb_dns_name" {
  description = "Application load balancer DNS name"
  value       = module.alb.load_balancer_dns_name
}

output "target_group_arn" {
  description = "Application Load Balancer target group ARN"
  value       = module.alb.target_group_arn
}

output "listener_arn" {
  description = "Application Load Balancer HTTP listener ARN"
  value       = module.alb.listener_arn
}

output "observability_sns_topic_arn" {
  description = "ARN of the observability alerts SNS topic"
  value       = module.observability_alarms.sns_topic_arn
}

output "observability_alarm_arns" {
  description = "ARNs of the observability CloudWatch alarms"
  value       = module.observability_alarms.alarm_arns
}
