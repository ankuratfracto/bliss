terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = var.region }

# In a management account, designate Security Hub admin (optional)
resource "aws_securityhub_organization_admin_account" "admin" {
  count            = var.organization_admin_account_id != "" ? 1 : 0
  admin_account_id = var.organization_admin_account_id
}

# In each account, enable Security Hub and standards
resource "aws_securityhub_account" "this" {}

# Standards subscriptions (IDs are stable for CIS/FSBP)
resource "aws_securityhub_standards_subscription" "fsbp" {
  count       = var.enable_fsbp_standard ? 1 : 0
  standards_arn = "arn:aws:securityhub:${var.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "cis" {
  count       = var.enable_cis_standard ? 1 : 0
  standards_arn = "arn:aws:securityhub:::standards/cis-aws-foundations-benchmark/v/1.4.0"
}
