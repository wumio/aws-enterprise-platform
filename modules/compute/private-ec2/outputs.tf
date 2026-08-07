output "instance_id" {
  description = "ID of the private EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the private EC2 instance"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "instance_name" {
  description = "Name of the private EC2 instance"
  value       = aws_instance.this.tags["Name"]
}
