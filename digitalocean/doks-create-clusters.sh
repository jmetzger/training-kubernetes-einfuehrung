#!/bin/bash
# Creates 16 DOKS clusters for Kubernetes training (tln1..tln16)
# Node type: s-4vcpu-8gb, autoscaling 3-5 nodes, region: fra1
# Usage: DIGITALOCEAN_TOKEN=<token> ./doks-create-clusters.sh

set -euo pipefail

REGION="fra1"
NODE_SIZE="s-4vcpu-8gb"
MIN_NODES=3
MAX_NODES=5
K8S_VERSION="1.32"  # adjust to latest stable: doctl kubernetes options versions
CLUSTER_PREFIX="tln"
COUNT=16

# Authenticate doctl with token from env
if [[ -z "${DIGITALOCEAN_TOKEN:-}" ]]; then
  echo "ERROR: Set DIGITALOCEAN_TOKEN environment variable first."
  echo "  export DIGITALOCEAN_TOKEN=<your-token>"
  exit 1
fi

doctl auth init --access-token "$DIGITALOCEAN_TOKEN" --context training >/dev/null 2>&1
doctl auth switch --context training >/dev/null 2>&1

# Get latest available patch version for the requested minor version
K8S_FULL_VERSION=$(doctl kubernetes options versions \
  | grep "^${K8S_VERSION}\." \
  | sort -V | tail -1 \
  | awk '{print $1}')

echo "==> Using Kubernetes version: ${K8S_FULL_VERSION}"
echo "==> Creating ${COUNT} clusters (${CLUSTER_PREFIX}1..${CLUSTER_PREFIX}${COUNT})"
echo "==> Node: ${NODE_SIZE}, Autoscale: ${MIN_NODES}-${MAX_NODES}, Region: ${REGION}"
echo ""

for i in $(seq 1 "$COUNT"); do
  CLUSTER_NAME="${CLUSTER_PREFIX}${i}"
  echo -n "  Creating ${CLUSTER_NAME}... "
  doctl kubernetes cluster create "${CLUSTER_NAME}" \
    --region "${REGION}" \
    --version "${K8S_FULL_VERSION}" \
    --node-pool "name=${CLUSTER_NAME}-pool;size=${NODE_SIZE};count=${MIN_NODES};auto-scale=true;min-nodes=${MIN_NODES};max-nodes=${MAX_NODES}" \
    --no-wait \
    2>&1 | tail -1 || true
  echo "submitted"
done

echo ""
echo "==> All cluster creation requests submitted (--no-wait)."
echo "==> Monitor with:  doctl kubernetes cluster list"
echo "==> Next step:     ./doks-download-kubeconfigs.sh"
