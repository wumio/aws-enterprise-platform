resource "aws_cloudwatch_log_group" "nginx" {
  name              = local.log_group_name
  retention_in_days = var.retention_in_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nginx-logs"
    }
  )
}
