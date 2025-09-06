-- OPA/Proxy evidence events (you'll write JSON here from your proxy)
CREATE EXTERNAL TABLE IF NOT EXISTS evidence.evidence_events (
  ts string,
  tenant string,
  event_type string,
  policy_version string,
  destination_host string,
  has_pii boolean,
  redaction_status string,
  vendor string,
  decision string
)
PARTITIONED BY (year string, month string, day string)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://YOUR-EVIDENCE-BUCKET/events/'
TBLPROPERTIES ('has_encrypted_data'='true');
