terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

module "evidence_lake" {
  source       = "../../modules/evidence_lake"
  region       = var.region
  bucket_name  = var.evidence_bucket_name
  retention_days = var.evidence_retention_days
}

module "audit_manager" {
  source                              = "../../modules/audit_manager"
  region                              = var.region
  assessment_reports_destination_bucket = module.evidence_lake.evidence_bucket_name
}

module "sfn_evidence_pack" {
  source               = "../../modules/stepfunctions_evidence_pack"
  region               = var.region
  evidence_bucket_name = module.evidence_lake.evidence_bucket_name
  notification_email   = var.notification_email
}

output "evidence_bucket" { value = module.evidence_lake.evidence_bucket_name }
