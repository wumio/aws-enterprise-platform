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
