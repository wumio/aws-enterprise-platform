# ALB security group
#checkov:skip=CKV2_AWS_5:Security group is provisioned by the security foundation before the downstream ALB resource is created by the compute stack.
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
#checkov:skip=CKV_AWS_260:HTTP is intentionally exposed on the internet-facing ALB; the ALB will handle HTTP-to-HTTPS redirection.
#checkov:skip=CKV_AWS_260:Application HTTP ingress is restricted to the ALB security group; Checkov does not fully interpret the referenced security group relationship.
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

  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-alb-sg-all-egress-rule"
    }
  )
}

# App Security Group
#checkov:skip=CKV2_AWS_5:Security group is provisioned by the security foundation before downstream application resources are created by the compute stack.
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
#checkov:skip=CKV_AWS_260:Application HTTP ingress is restricted to the ALB security group; Checkov does not fully interpret the security-group reference.
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

# App SG egress rule to DB SG
resource "aws_vpc_security_group_egress_rule" "app_egress_db" {
  security_group_id = aws_security_group.app.id

  description = "Allow outbound traffic to DB SG"

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.db.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-app-sg-db-egress-rule"
    }
  )
}

# App SG egress rule to any
resource "aws_vpc_security_group_egress_rule" "app_egress_all" {
  security_group_id = aws_security_group.app.id

  description = "Allow outbound traffic"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-security-app-sg-all-egress-rule"
    }
  )
}

# Database Security Group
#checkov:skip=CKV2_AWS_5:Security group is provisioned by the security foundation before downstream database resources are created.
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
