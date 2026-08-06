output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_app_subnet_cidrs" {
  description = "Private application subnet CIDR blocks"
  value       = aws_subnet.private_app[*].cidr_block
}

output "private_data_subnet_ids" {
  description = "private data subnet IDs"
  value       = aws_subnet.private_data[*].id
}

output "private_data_subnet_cidrs" {
  description = "Private data subnet CIDR blocks"
  value       = aws_subnet.private_data[*].cidr_block
}
