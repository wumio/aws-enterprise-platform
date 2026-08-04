# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = "/aws/vpc/${local.name_prefix}/flow-logs"

  retention_in_days = 90
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc-flow-logs"
    }
  )
}

# IAM role assumed by the VPC Flow Logs service to publish logs to CloudWatch
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc-flow-logs-role"
    }
  )
}

# IAM policy for the VPC Flow Logs service to publish logs to CloudWatch
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs-policy"

  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]

        Resource = "*"
      }
    ]
  })
}

# Enable VPC Flow Logs for the specified VPC and send logs to CloudWatch
resource "aws_flow_log" "vpc" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc-flow-logs"
    }
  )
}
