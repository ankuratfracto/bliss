terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = var.region }

resource "aws_s3_bucket" "trail" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_acl" "trail" {
  bucket = aws_s3_bucket.trail.id
  acl    = "private"
}

resource "aws_cloudtrail" "org" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.trail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = var.is_organization_trail
}
