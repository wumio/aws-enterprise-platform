# Reference current data source instead of hard-coding it to make module portable and reusable across all environments.
data "aws_region" "current" {}

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-ssm-endpoints-sg"
  description = "Security group for Systems Manager VPC interface endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-endpoints-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.this.id

  description = "Allow HTTPS from private subnets"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = each.value

  for_each = toset(var.private_subnet_cidrs)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-endpoints-https-ingress"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id

  description = "Allow HTTPS outbound traffic"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-endpoints-https-egress"
    }
  )
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${data.aws_region.current.region}.ssm"

  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.this.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssm-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${data.aws_region.current.region}.ssmmessages"

  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.this.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ssmmessages-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${data.aws_region.current.region}.ec2messages"

  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.this.id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ec2messages-endpoint"
    }
  )
}
