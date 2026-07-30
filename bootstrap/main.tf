# Terraform backend bootstrap resources
#
# Creates:
# - KMS key for encryption
# - DynamoDB table for state locking
# - S3 bucket for Terraform state
# - S3 bucket to collect access logs

# Create customer-managed KMS key
resource "aws_kms_key" "terraform_state" {
  description             = "Customer-managed KMS key for Terraform state encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "${var.company_name}-${var.environment}-kms-tfstate"
  }
}

# KMS key policy
resource "aws_kms_key_policy" "terraform_state" {
  key_id = aws_kms_key.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "Enable IAM User Permissions"

        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action = "kms:*"

        Resource = "*"
      }
    ]
  })
}

# Alias created to make the key human-readable as in alias/nhs-bootstrap-tfstate
resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.company_name}-${var.environment}-tfstate"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# Create DynamoDB lock table
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.company_name}-${var.environment}-dynamodb-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"

  }

  server_side_encryption { # Enable DynamoDB CMK encryption
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    name = "${var.company_name}-${var.environment}-dynamodb-lock"

  }

}

# Create S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.company_name}-${var.environment}-s3-tfstate"
}

# Enable S3 bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn

      sse_algorithm = "aws:kms"
    }
  }
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lock S3 bucket access to owner
resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Deny HTTP transport access - only HTTPS allowed
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Abort incomplete uploads to S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform-state-retention"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# New bucket - Create S3 bucket to collect access logs
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.company_name}-${var.environment}-s3-access-logs"

  tags = {
    Name = "${var.company_name}-${var.environment}-s3-access-logs"
  }
}

# Enable S3 access logs bucket versioning
resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 access log collection
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "terraform-state/"
}

# Enable S3 access logs bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn

      sse_algorithm = "aws:kms"
    }

    bucket_key_enabled = true
  }

}

# Block public access to S3 bucket access logs
resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lock S3 access logs bucket access to owner
resource "aws_s3_bucket_ownership_controls" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Deny HTTP transport access - only HTTPS allowed to access logs bucket
resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.access_logs.arn,
          "${aws_s3_bucket.access_logs.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Abort incomplete uploads to S3 access logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "access-log-retention"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}
# CI pipeline validation test
