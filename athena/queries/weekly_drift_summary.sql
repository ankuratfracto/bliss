-- Weekly drift summary (sketch)
SELECT
  year, month, day,
  json_extract_scalar(line, '$.summary.security_hub_count') as sec_hub_count
FROM evidence.evidence_events -- replace with your index path if different
CROSS JOIN UNNEST (split(regexp_replace(ts, '\\n', ''), '\\n')) AS t(line)
WHERE year = year(current_date)
ORDER BY year, month, day;
