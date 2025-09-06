variable "region" { type = string }
variable "enable_cis_standard" { type = bool default = true }
variable "enable_fsbp_standard" { type = bool default = true }
variable "organization_admin_account_id" { type = string default = "" } # set in management account
