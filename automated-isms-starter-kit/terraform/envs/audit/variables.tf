variable "region" { type = string }
variable "aws_profile" { type = string default = "audit" }
variable "evidence_bucket_name" { type = string }
variable "evidence_retention_days" { type = number default = 365 }
variable "notification_email" { type = string }
