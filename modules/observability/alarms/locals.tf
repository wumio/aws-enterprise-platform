locals {
  name_prefix = "${var.name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
