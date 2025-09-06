#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Ensure you have AWS CLI configured with profiles: management, audit, workloads"
echo "[INFO] Running terraform validate on audit & workloads envs"

( cd ../terraform/envs/audit && terraform init -input=false && terraform validate )
( cd ../terraform/envs/workloads && terraform init -input=false && terraform validate )

echo "[OK] Starter kit validated locally."
