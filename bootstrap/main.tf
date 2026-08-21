# Terraform backend bootstrap resources
#
# Creates:
# - KMS key for encryption and decryption
# - DynamoDB table for state locking
# - S3 bucket for Terraform state
# - S3 bucket for Terraform state DR
# - S3 cross-region replication
# - S3 bucket to collect access logs

# Create customer-managed primary KMS key
resource "aws_kms_key" "terraform_state" {
  description             = "Customer-managed KMS key for Terraform state encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "${var.company_name}-${var.environment}-kms-tfstate"
  }
}

# KMS primary key policy
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
      },
      {
        Sid    = "AllowS3ReplicationToDecrypt"
        Effect = "Allow"

        Principal = {
          AWS = aws_iam_role.terraform_state_replication.arn
        }

        Action = [
          "kms:Decrypt"
        ]

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

# Create customer-managed KMS key for Terraform state DR
resource "aws_kms_key" "terraform_state_dr" {
  provider = aws.dr

  description             = "Customer-managed KMS key for Terraform state DR"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "${var.company_name}-${var.environment}-kms-tfstate-dr"
  }
}

# KMS key policy for Terraform state DR
resource "aws_kms_key_policy" "terraform_state_dr" {
  provider = aws.dr

  key_id = aws_kms_key.terraform_state_dr.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3ReplicationToEncrypt"
        Effect = "Allow"

        Principal = {
          AWS = aws_iam_role.terraform_state_replication.arn
        }

        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = "*"
      }
    ]
  })
}

# Alias for the DR KMS key
resource "aws_kms_alias" "terraform_state_dr" {
  provider = aws.dr

  name          = "alias/${var.company_name}-${var.environment}-tfstate-dr"
  target_key_id = aws_kms_key.terraform_state_dr.key_id
}

# IAM role assumed by Amazon S3 for cross-region replication
resource "aws_iam_role" "terraform_state_replication" {
  name = "${var.company_name}-${var.environment}-tfstate-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowS3ReplicationAssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.company_name}-${var.environment}-tfstate-replication"
  }
}

# Least-privilege permissions for S3 cross-region replication
resource "aws_iam_role_policy" "terraform_state_replication" {
  name = "${var.company_name}-${var.environment}-tfstate-replication"
  role = aws_iam_role.terraform_state_replication.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadSourceState"
        Effect = "Allow"

        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "ReadSourceObjectVersions"
        Effect = "Allow"

        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging"
        ]

        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "DecryptSourceState"
        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = aws_kms_key.terraform_state.arn
      },
      {
        Sid    = "ReplicateToDestination"
        Effect = "Allow"

        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]

        Resource = "${aws_s3_bucket.terraform_state_dr.arn}/*"
      },
      {
        Sid    = "EncryptDestinationState"
        Effect = "Allow"

        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = aws_kms_key.terraform_state_dr.arn
      }

    ]
  })
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

# Create S3 bucket for Terraform state
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

# Deny insecure transport to Terraform state bucket
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

# Abort incomplete uploads to Terraform state S3 bucket
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

# Create S3 bucket for Terraform state disaster recovery
resource "aws_s3_bucket" "terraform_state_dr" {
  provider = aws.dr

  bucket = "${var.company_name}-${var.environment}-s3-tfstate-dr"
}

# Enable S3 bucket versioning for Terraform state DR
resource "aws_s3_bucket_versioning" "terraform_state_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.terraform_state_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable S3 bucket encryption for Terraform state DR
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.terraform_state_dr.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state_dr.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block public access to Terraform state DR bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.terraform_state_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce bucket-owner ownership for Terraform state DR
resource "aws_s3_bucket_ownership_controls" "terraform_state_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.terraform_state_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Deny insecure transport to Terraform state DR bucket
resource "aws_s3_bucket_policy" "terraform_state_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.terraform_state_dr.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          aws_s3_bucket.terraform_state_dr.arn,
          "${aws_s3_bucket.terraform_state_dr.arn}/*"
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

# Abort incomplete uploads to Terraform state DR S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.terraform_state_dr.id

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

# Configure cross-region replication for Terraform state
resource "aws_s3_bucket_replication_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  role   = aws_iam_role.terraform_state_replication.arn

  # S3 requires source bucket versioning before replication can be enabled
  depends_on = [
    aws_s3_bucket_versioning.terraform_state,
    aws_s3_bucket_versioning.terraform_state_dr
  ]

  rule {
    id       = "terraform-state-dr"
    priority = 1
    status   = "Enabled"

    filter {}

    # terraform state objects are SSE-KMS encrypted
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    # Do not propagate delete markers to the DR copy
    delete_marker_replication {
      status = "Disabled"
    }

    destination {
      bucket = aws_s3_bucket.terraform_state_dr.arn

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.terraform_state_dr.arn
      }
    }
  }
}

# New bucket - Create S3 bucket to collect access logs
#checkov:skip=CKV_AWS_144:Cross-region replication is intentionally deferred for the development access-log bucket; multi-region DR is outside the current bootstrap scope.
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
