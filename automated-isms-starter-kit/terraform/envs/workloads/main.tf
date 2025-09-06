terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# Minimal baseline: Config + Security Hub; point Config to evidence bucket for delivery
module "config_baseline" {
  source              = "../../modules/config_baseline"
  region              = var.region
  s3_bucket_for_config = var.evidence_bucket_name
}

module "security_hub" {
  source  = "../../modules/security_hub_org"
  region  = var.region
  enable_cis_standard   = true
  enable_fsbp_standard  = true
}

# (Optional) account-level CloudTrail if you don't use org trail
module "cloudtrail_account" {
  source                = "../../modules/cloudtrail_org"
  region                = var.region
  trail_name            = "acct-trail"
  is_organization_trail = false
  s3_bucket_name        = var.trail_bucket_name
}

output "config_delivery" { value = var.evidence_bucket_name }
