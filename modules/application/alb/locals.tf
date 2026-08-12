locals {
  name_prefix = "${var.name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}
