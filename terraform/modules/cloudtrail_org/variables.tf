variable "region" { type = string }
variable "trail_name" { type = string default = "org-trail" }
variable "is_organization_trail" { type = bool default = false }
variable "s3_bucket_name" { type = string }
