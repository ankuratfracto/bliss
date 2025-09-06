-- Security Hub findings snapshots written by the Evidence Pack Lambda
CREATE EXTERNAL TABLE IF NOT EXISTS evidence.securityhub_findings (
  count int,
  items array<map<string, string>>
)
PARTITIONED BY (year string, month string, day string)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://YOUR-EVIDENCE-BUCKET/securityhub/findings/'
TBLPROPERTIES ('has_encrypted_data'='true');
