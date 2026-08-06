locals {
  name_prefix = "${var.name}-${var.environment}-security"

  common_tags = {
    Project     = var.name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
