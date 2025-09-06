terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = var.region }

resource "aws_iam_role" "config_role" {
  name = "AWSConfigRecorderRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSConfigRole"]
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel" {
  name           = "default"
  s3_bucket_name = var.s3_bucket_for_config
  depends_on     = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
}

# A couple of baseline managed rules (expand as needed)
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "cloudtrail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "s3_encrypted" {
  name = "s3-bucket-server-side-encryption-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}
