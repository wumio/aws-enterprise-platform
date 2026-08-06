locals {
  name_prefix = "${var.name}-${var.environment}"

  role_name             = "${local.name_prefix}-ec2-role"
  instance_profile_name = "${local.name_prefix}-ec2-profile"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
