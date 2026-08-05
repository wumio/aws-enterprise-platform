# VPC
#checkov:skip=CKV2_AWS_11:VPC Flow Logs are intentionally provisioned by the security foundation stack rather than the networking stack.
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-vpc"
    }
  )
}

# AWS Default Security Group
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-igw"
    }
  )
}
