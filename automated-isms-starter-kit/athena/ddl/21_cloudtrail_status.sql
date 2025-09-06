-- CloudTrail status snapshots
CREATE EXTERNAL TABLE IF NOT EXISTS evidence.cloudtrail_status (
  trails array<map<string, string>>,
  statuses array<map<string, string>>
)
PARTITIONED BY (year string, month string, day string)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://YOUR-EVIDENCE-BUCKET/cloudtrail/status/'
TBLPROPERTIES ('has_encrypted_data'='true');
