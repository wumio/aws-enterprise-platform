# Elastic IP
#checkov:skip=CKV2_AWS_19:EIP is intentionally attached to the NAT Gateway rather than an EC2 instance to provide internet egress for private subnets.
resource "aws_eip" "nat" {
  domain = "vpc"

  count = var.enable_nat_gateway ? 1 : 0

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-nat-eip"
    }
  )
}

# NAT Gateway - Initial cost-aware design using 1 NAT Gateway for the 2 AZs
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat[0].id

  count = var.enable_nat_gateway ? 1 : 0

  subnet_id = aws_subnet.public[0].id # Placing NAT Gateway in the first public subnet

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-nat"
    }
  )
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-private-rt"
      Tier = "private"
    }
  )
}

# Default Route
resource "aws_route" "private_default" {
  route_table_id = aws_route_table.private.id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.this[0].id

  count = var.enable_nat_gateway ? 1 : 0
}

# Associate Private App Subnets
resource "aws_route_table_association" "private_app" {
  count = length(aws_subnet.private_app)

  subnet_id = aws_subnet.private_app[count.index].id

  route_table_id = aws_route_table.private.id
}

# Associate Private Data Subnets
resource "aws_route_table_association" "private_data" {
  count = length(aws_subnet.private_data)

  subnet_id = aws_subnet.private_data[count.index].id

  route_table_id = aws_route_table.private.id
}
