# Automated ISMS Starter Kit (AWS + GCP Vision + LLMs)

This starter kit gives you a **policy-as-code + continuous control monitoring** foundation to
automate ISO 27001 evidence collection and compliance reporting for your IDP platform
(AWS ap-south-1, Google Cloud Vision OCR, OpenAI/Gemini/Claude).

**Highlights**
- Terraform modules to deploy an **evidence lake (S3 Object Lock + KMS)**, **CloudTrail (org or account)**,
  **AWS Config + Conformance rules**, **Security Hub**, **Audit Manager registration**, and a
  **monthly Evidence Pack Step Functions** workflow (collects findings, snapshots to S3, emails summary).
- OPA policy pack for **LLM/OCR compliance** (egress allowlist, redaction required, Vision location required)
  with unit tests you can run via `opa test`.
- Athena DDLs + example queries and a QuickSight S3 manifest to visualize posture & trends.

> ⚠️ ISO 27001 still requires *human* actions (risk decisions, internal audit, management review, SoA rationale).
> This kit automates the rest (controls, drift detection, evidence, and reporting).

## Structure

```
automated-isms-starter-kit/
├─ terraform/
│  ├─ envs/
│  │  ├─ management/         # (optional) org-level features (Security Hub admin, CloudTrail org trail)
│  │  ├─ audit/              # evidence lake + Audit Manager registration + Step Functions evidence pack
│  │  └─ workloads/          # per-account baseline (Config rules, Security Hub, GuardDuty, Macie)
│  └─ modules/               # reusable Terraform modules
├─ lambda/evidence_pack/     # Lambda to collect findings & snapshot evidence to S3
├─ state_machines/           # Step Functions definition (ASL JSON)
├─ opa/                      # OPA Rego policies + tests
├─ athena/ddl/               # Athena external table DDLs and queries
├─ quicksight/               # S3 manifest example for QuickSight ingest
└─ scripts/                  # helper scripts
```

## Quick start

1) **Decide accounts**: Management (org root), Audit (logs/evidence), and one or more workload accounts.
2) **Create AWS profiles** in your workstation (e.g., `management`, `audit`, `workloads`).  
3) **Deploy management (optional but recommended)**  
   ```bash
   cd terraform/envs/management
   terraform init && terraform apply -var='region=ap-south-1' -var='security_hub_admin_account_id=<AUDIT_ACCOUNT_ID>'
   ```
4) **Deploy audit** (evidence lake, Audit Manager registration, Step Functions evidence pack)  
   ```bash
   cd terraform/envs/audit
   terraform init && terraform apply -var='region=ap-south-1' -var='evidence_bucket_name=<globally-unique-bucket>' -var='notification_email=<you@example.com>'
   ```
5) **Deploy workload baseline** in each account (Config + Security Hub + GuardDuty + Macie)  
   ```bash
   cd terraform/envs/workloads
   terraform init && terraform apply -var='region=ap-south-1' -var='evidence_bucket_name=<same-as-audit-bucket>'
   ```

6) **Run OPA tests**  
   ```bash
   cd opa
   opa test .
   ```

7) **Create Athena DB and tables**  
   - Open Athena console, set query result location to the evidence bucket (e.g., `s3://<bucket>/athena-results/`).
   - Run the DDLs in `athena/ddl/*.sql` (update the S3 paths first).

8) **Connect QuickSight** (optional)  
   - Use the `quicksight/s3_manifest_evidence.json` to import S3 data, or connect QuickSight directly to Athena.

## Notes

- **S3 Object Lock** buckets must be created with object lock enabled from the start (Terraform handles this here).
- **CloudTrail org trail** requires AWS Organizations; if you don’t use org trails, the per-account trail works too.
- **Audit Manager**: this kit registers your account and sets the S3 destination. Creating an assessment from the
  built-in “ISO/IEC 27001:2013 Annex A” framework can be done in console or extended later in code.
- **GCP Vision**: ensure your apps call Vision with an explicit `us` or `eu` location and run through your LLM/OCR proxy.

MIT License.
