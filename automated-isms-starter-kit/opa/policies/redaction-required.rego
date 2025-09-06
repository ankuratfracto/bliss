package idp.compliance.redaction

# Deny LLM/OCR requests unless redaction passed OR input contains no PII
# Input example:
# {
#   "contains_pii": true,
#   "redaction_status": "passed"  # or "skipped"/"failed"
# }

deny[msg] {
  input.contains_pii == true
  not input.redaction_status == "passed"
  msg := "PII detected but redaction not passed"
}
