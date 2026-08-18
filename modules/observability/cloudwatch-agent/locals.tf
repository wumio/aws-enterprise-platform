locals {
  name_prefix = "${var.name}-${var.environment}"

  log_group_name = "/aws/ec2/${local.name_prefix}/nginx"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
