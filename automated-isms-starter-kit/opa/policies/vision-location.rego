package idp.compliance.vision

# Enforce Vision location is explicitly set to 'us' or 'eu'
# Input example: { "location": "us" }

deny[msg] {
  not input.location
  msg := "Vision location missing (must be 'us' or 'eu')"
}

deny[msg] {
  input.location
  not input.location == "us"
  not input.location == "eu"
  msg := sprintf("Vision location '%v' not allowed; must be 'us' or 'eu'", [input.location])
}
