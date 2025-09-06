terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

module "security_hub_org" {
  source                         = "../../modules/security_hub_org"
  region                         = var.region
  organization_admin_account_id  = var.security_hub_admin_account_id
  enable_cis_standard            = true
  enable_fsbp_standard           = true
}

# Optional org-wide CloudTrail (requires AWS Organizations)
module "cloudtrail_org" {
  source                 = "../../modules/cloudtrail_org"
  region                 = var.region
  trail_name             = var.trail_name
  is_organization_trail  = true
  s3_bucket_name         = var.trail_bucket_name
}
