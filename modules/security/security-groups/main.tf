# ALB security group
resource "aws_security_group" "alb" {
  name = "${local.name_prefix}-security-alb-sg"

  description = "Security group for the application load balancer"

  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-alb-sg"
    }
  )
}

# ALB SG HTTP ingress rule
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTP inbound traffic"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-alb-sg-http-ingress-rule"
    }
  )
}

# ALB SG HTTPS ingress rule
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  description = "Allow HTTPS inbound traffic"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-alb-sg-https-ingress-rule"
    }
  )
}

# ALB SG allow all egress rule
resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb.id

  description = "Allow outbound traffic"

  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-alb-sg-all-egress-rule"
    }
  )
}

# App Security Group
resource "aws_security_group" "app" {
  name = "${local.name_prefix}-security-app-sg"

  description = "Security group for the application"

  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-app-sg"
    }
  )
}

# App SG HTTP ingress rule from ALB SG
resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id

  description = "Allow inbound traffic only from the ALB SG"

  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-app-sg-http-ingress-rule"
    }
  )
}

# App SG HTTP egress rule
resource "aws_vpc_security_group_egress_rule" "app_egress_all" {
  security_group_id = aws_security_group.app.id

  description = "Allow outbound traffic"

  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-app-sg-all-egress-rule"
    }
  )
}

# Database Security Group
resource "aws_security_group" "db" {
  name = "${local.name_prefix}-security-db-sg"

  description = "Security group for the database"

  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-db-sg"
    }
  )
}

# Database SG ingress rule from App SG
resource "aws_vpc_security_group_ingress_rule" "db_postgres_ingress" {
  security_group_id = aws_security_group.db.id

  description = "Allow database traffic from the App SG"

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-db-sg-postgres-ingress-rule"
    }
  )
}

# Database SG HTTP egress rule
resource "aws_vpc_security_group_egress_rule" "db_egress_all" {
  security_group_id = aws_security_group.db.id

  description = "Allow outbound traffic"

  from_port   = -1
  to_port     = -1
  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-db-sg-all-egress-rule"
    }
  )
}
