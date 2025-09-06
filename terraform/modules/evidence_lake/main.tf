terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_kms_key" "evidence" {
  description             = "KMS key for evidence bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_s3_bucket" "evidence" {
  bucket = var.bucket_name

  # Must be enabled at creation time
  object_lock_enabled = true

  tags = {
    purpose = "evidence-lake"
  }
}

resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.evidence.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    id     = "expire-noncurrent"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = max(90, var.retention_days)
    }
  }
}

# Default Object Lock: Compliance mode
resource "aws_s3_bucket_object_lock_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.retention_days
    }
  }
}

# Require KMS encryption on puts
data "aws_iam_policy_document" "evidence_bucket_policy" {
  statement {
    sid = "DenyUnEncryptedObjectUploads"
    effect = "Deny"
    principals { type = "*"; identifiers = ["*"] }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.evidence.arn}/*"]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid = "DenyIncorrectEncryptionHeader"
    effect = "Deny"
    principals { type = "*"; identifiers = ["*"] }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.evidence.arn}/*"]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.evidence.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  policy = data.aws_iam_policy_document.evidence_bucket_policy.json
}

output "evidence_bucket_name" { value = aws_s3_bucket.evidence.bucket }
output "evidence_kms_key_arn" { value = aws_kms_key.evidence.arn }
