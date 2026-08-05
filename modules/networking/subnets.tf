# Public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-public-${count.index + 1}"
      Tier = "public"
    }
  )
}

# Private application subnets
resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  cidr_block = var.private_app_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-private-app-${count.index + 1}"
      Tier = "private-app"
    }
  )
}

# Private data subnets
resource "aws_subnet" "private_data" {
  count = length(var.private_data_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  cidr_block = var.private_data_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${var.environment}-network-private-data-${count.index + 1}"
      Tier = "private-data"
    }
  )
}
