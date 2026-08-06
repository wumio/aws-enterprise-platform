output "security_group_id" {
  description = "ID of the security group used by SSM VPC interface endpoints"
  value       = aws_security_group.this.id
}

output "endpoint_ids" {
  description = "IDs of the Systems Manager VPC interface endpoints"
  value = {
    ssm         = aws_vpc_endpoint.ssm.id
    ssmmessages = aws_vpc_endpoint.ssmmessages.id
    ec2messages = aws_vpc_endpoint.ec2messages.id
  }
}
