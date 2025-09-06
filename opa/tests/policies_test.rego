package idp.compliance.tests

import data.idp.compliance.egress
import data.idp.compliance.redaction
import data.idp.compliance.vision

test_egress_allows_known_host {
  egress.allow with input as {"destination_host": "api.openai.com", "allowlist": ["api.openai.com"]}
}

test_egress_denies_unknown_host {
  not egress.allow with input as {"destination_host": "evil.example.com", "allowlist": ["api.openai.com"]}
}

test_redaction_blocks_when_pii_and_not_passed {
  redaction.deny with input as {"contains_pii": true, "redaction_status": "skipped"}
}

test_redaction_allows_when_no_pii {
  not redaction.deny with input as {"contains_pii": false}
}

test_vision_requires_location {
  vision.deny with input as {}
}

test_vision_accepts_us_or_eu {
  not vision.deny with input as {"location": "us"}
  not vision.deny with input as {"location": "eu"}
}

test_vision_rejects_other_regions {
  vision.deny with input as {"location": "asia-south1"}
}
