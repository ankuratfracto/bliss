terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = var.region }

# Register Audit Manager in this account and set the default report destination
resource "aws_auditmanager_account_registration" "this" {
  kms_key_arn                       = null
  deregister                         = false

  default_assessment_reports_destination {
    destination      = "S3"
    destination_arn  = "arn:aws:s3:::${var.assessment_reports_destination_bucket}"
  }
}
