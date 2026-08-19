# Elastic IPs for NAT Gateways
#checkov:skip=CKV2_AWS_19:EIP is intentionally attached to the NAT Gateway rather than an EC2 instance to provide internet egress for private subnets.
resource "aws_eip" "nat" {
  domain = "vpc"

  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-nat-eip-${count.index + 1}"
    }
  )
}

# NAT Gateway - one per AZ for resilient private subnet egress
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat[count.index].id

  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  subnet_id = aws_subnet.public[count.index].id

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-nat-${count.index + 1}"
    }
  )
}

# Private Route Tables - one per Availability Zone
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-private-rt-${count.index + 1}"
      Tier = "private"
    }
  )
}

# Default Route from each private route table to the NAT Gateway in the same AZ
resource "aws_route" "private_default" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  route_table_id = aws_route_table.private[count.index].id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.this[count.index].id
}

# Associate private application subnets with their AZ-specific route tables
resource "aws_route_table_association" "private_app" {
  count = length(aws_subnet.private_app)

  subnet_id = aws_subnet.private_app[count.index].id

  route_table_id = aws_route_table.private[count.index].id
}

# Associate private data subnets with their AZ-specific route tables
resource "aws_route_table_association" "private_data" {
  count = length(aws_subnet.private_data)

  subnet_id = aws_subnet.private_data[count.index].id

  route_table_id = aws_route_table.private[count.index].id
}
