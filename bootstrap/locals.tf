
locals {
  common_tags = {
    Environment = var.environment
    Project     = "Enterprise Landing Zone"
    MangedBy    = "Terraform"
    owner       = "Infrastructure Team"
  }

}
