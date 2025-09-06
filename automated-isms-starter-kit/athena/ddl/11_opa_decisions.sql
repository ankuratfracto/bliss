-- OPA decision logs (if you choose to write raw decisions)
CREATE EXTERNAL TABLE IF NOT EXISTS evidence.opa_decisions (
  input map<string, string>,
  result map<string, string>,
  ts string
)
PARTITIONED BY (year string, month string, day string)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://YOUR-EVIDENCE-BUCKET/opa/decisions/'
TBLPROPERTIES ('has_encrypted_data'='true');
