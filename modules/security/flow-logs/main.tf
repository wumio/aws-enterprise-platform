data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  log_group_name = "/aws/vpc/${local.name_prefix}/flow-logs"

  log_group_arn = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"
}

# KMS key used to encrypt VPC Flow Logs in CloudWatch LogsOB
resource "aws_kms_key" "vpc_flow_logs" {
  description         = "KMS key for ${local.name_prefix} VPC Flow Logs"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableAccountRootPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsUseOfKey"
        Effect = "Allow"

        Principal = {
          Service = "logs.${data.aws_region.current.region}.amazonaws.com"
        }

        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]

        Resource = "*"

        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = local.log_group_arn
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc-flow-logs-kms"
    }
  )
}

resource "aws_kms_alias" "vpc_flow_logs" {
  name          = "alias/${local.name_prefix}-vpc-flow-logs"
  target_key_id = aws_kms_key.vpc_flow_logs.key_id
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = local.log_group_name

  retention_in_days = var.retention_in_days
  kms_key_id        = aws_kms_key.vpc_flow_logs.arn

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

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }

          ArnLike = {
            "aws:SourceArn" = "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
          }
        }
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

# IAM policy for the VPC Flow Logs service to publish logs to the
# Terraform-managed CloudWatch log group
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs-policy"

  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DescribeLogGroups"
        Effect = "Allow"

        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]

        Resource = aws_cloudwatch_log_group.vpc_flow_logs.arn
      },
      {
        Sid    = "WriteFlowLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
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
