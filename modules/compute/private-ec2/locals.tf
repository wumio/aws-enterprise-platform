locals {
  name_prefix = "${var.name}-${var.environment}"

  instance_name = "${local.name_prefix}-private-ec2"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
