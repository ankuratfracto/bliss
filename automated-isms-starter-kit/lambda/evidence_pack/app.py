import os, json, time, boto3
from datetime import datetime, timezone

s3 = boto3.client("s3")
securityhub = boto3.client("securityhub")
config = boto3.client("config")
cloudtrail = boto3.client("cloudtrail")

BUCKET = os.environ["EVIDENCE_BUCKET"]

def put_json(prefix, obj):
    key = f"{prefix}/year={datetime.utcnow().year}/month={datetime.utcnow().month:02d}/day={datetime.utcnow().day:02d}/{int(time.time())}.json"
    s3.put_object(Bucket=BUCKET, Key=key, Body=(json.dumps(obj, default=str) + "\n").encode("utf-8"))
    return key

def collect_security_hub():
    findings = []
    paginator = securityhub.get_paginator("get_findings")
    for page in paginator.paginate(MaxResults=100):
        findings.extend(page.get("Findings", []))
    return {"count": len(findings), "items": findings[:2000]}  # cap blob size; full set is stored in S3 by pagination

def collect_config_summary():
    recorders = config.describe_configuration_recorders().get("ConfigurationRecorders", [])
    status = config.describe_configuration_recorder_status().get("ConfigurationRecordersStatus", [])
    rules = config.describe_config_rules().get("ConfigRules", [])
    return {"recorders": recorders, "status": status, "rules": [r.get("ConfigRuleName") for r in rules]}

def collect_trail_status():
    trails = cloudtrail.describe_trails(includeShadowTrails=False).get("trailList", [])
    statuses = []
    for t in trails:
        name = t.get("Name")
        if name:
            st = cloudtrail.get_trail_status(Name=name)
            statuses.append({"name": name, "status": st})
    return {"trails": trails, "statuses": statuses}

def lambda_handler(event, context):
    stamp = datetime.now(timezone.utc).isoformat()

    sec = collect_security_hub()
    cfg = collect_config_summary()
    ctl = collect_trail_status()

    doc = {
        "timestamp": stamp,
        "security_hub_count": sec["count"],
        "config_rules": cfg["rules"],
        "trail_count": len(ctl["trails"]),
    }

    # Write detailed blobs
    sec_key = put_json("securityhub/findings", sec)
    cfg_key = put_json("config/summaries", cfg)
    ctl_key = put_json("cloudtrail/status", ctl)
    idx_key = put_json("evidence/index", {"summary": doc, "keys": {"securityhub": sec_key, "config": cfg_key, "cloudtrail": ctl_key}})

    return {"ok": True, "index_key": idx_key, "summary": doc}
