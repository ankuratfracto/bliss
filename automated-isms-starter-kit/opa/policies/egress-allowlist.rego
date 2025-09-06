package idp.compliance.egress

default allow = false

# Input example:
# {
#   "destination_host": "api.openai.com",
#   "allowlist": ["api.openai.com", "vision.googleapis.com", "generativelanguage.googleapis.com", "api.anthropic.com"]
# }

allow {
  input.destination_host != ""
  input.allowlist[_] == input.destination_host
}
