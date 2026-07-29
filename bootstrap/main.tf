# Terraform backend bootstrap resources
#
# Creates:
# - S3 bucket for Terraform state
# - DynamoDB table for state locking
# - KMS key for encryption

resource "aws_kms_key" "terraform_state" {
  description             = "Customer-managed KMS key for Terraform state encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "${var.company_name}-${var.environment}-kms-tfstate"
  }
}

# Alias created to make the key human-readable as in alias/nhs-bootstrap-tfstate
resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.company_name}-${var.environment}-tfstate"
  target_key_id = aws_kms_key.terraform_state.key_id
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.company_name}-${var.environment}-s3-tfstate"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}


# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn

      sse_algorithm = "aws:kms"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB lock table
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.company_name}-${var.environment}-dynamodb-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"

  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    name = "${var.company_name}-${var.environment}-dynamodb-lock"

  }

}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

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

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform-state-retention"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# CI pipeline validation test
