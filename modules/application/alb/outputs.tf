output "load_balancer_id" {
  description = "Application Load Balancer ID"
  value       = aws_lb.this.id
}

output "load_balancer_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "Application Load Balancer target group ARN"
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "Application Load Balancer HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}
