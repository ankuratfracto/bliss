variable "region" { type = string }
variable "aws_profile" { type = string default = "management" }
variable "security_hub_admin_account_id" { type = string } # set to the Audit account ID
variable "trail_name" { type = string default = "org-trail" }
variable "trail_bucket_name" { type = string }
