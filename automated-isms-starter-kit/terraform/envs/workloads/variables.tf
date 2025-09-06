variable "region" { type = string }
variable "aws_profile" { type = string default = "workloads" }
variable "evidence_bucket_name" { type = string }     # use the audit account bucket (with proper bucket policy grants)
variable "trail_bucket_name" { type = string }        # a per-account trail bucket (or reuse centralized one with proper policy)
