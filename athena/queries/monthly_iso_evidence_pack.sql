-- Monthly ISO Evidence Pack skeleton query (adjust columns)
WITH latest_finds AS (
  SELECT *
  FROM evidence.securityhub_findings
  WHERE year = year(current_date)
    AND month = lpad(cast(month(current_date) as varchar), 2, '0')
)
SELECT
  current_date as report_date,
  (SELECT max(count) FROM latest_finds) as securityhub_findings_count
;
