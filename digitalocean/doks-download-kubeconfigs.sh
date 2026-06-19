#!/bin/bash
# Downloads kubeconfigs for all 16 training clusters and copies them to bastion.
# Kubeconfigs land on bastion at /tmp/config.tln1 .. /tmp/config.tln16
# Usage: DIGITALOCEAN_TOKEN=<token> BASTION=161.35.210.204 ./doks-download-kubeconfigs.sh

set -euo pipefail

CLUSTER_PREFIX="tln"
COUNT=16
BASTION="${BASTION:-161.35.210.204}"
BASTION_USER="${BASTION_USER:-root}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_nopass}"
TMP_DIR=$(mktemp -d)

if [[ -z "${DIGITALOCEAN_TOKEN:-}" ]]; then
  echo "ERROR: Set DIGITALOCEAN_TOKEN environment variable first."
  exit 1
fi

doctl auth init --access-token "$DIGITALOCEAN_TOKEN" --context training >/dev/null 2>&1
doctl auth switch --context training >/dev/null 2>&1

trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Waiting for all clusters to become running..."
for i in $(seq 1 "$COUNT"); do
  NAME="${CLUSTER_PREFIX}${i}"
  echo -n "  ${NAME}: "
  while true; do
    STATUS=$(doctl kubernetes cluster get "$NAME" --format Status --no-header 2>/dev/null || echo "not-found")
    echo -n "${STATUS} "
    if [[ "$STATUS" == "running" ]]; then
      echo "ok"
      break
    elif [[ "$STATUS" == "not-found" ]]; then
      echo "MISSING — skipping"
      break
    fi
    sleep 15
  done
done

echo ""
echo "==> Downloading kubeconfigs..."
for i in $(seq 1 "$COUNT"); do
  NAME="${CLUSTER_PREFIX}${i}"
  LOCAL_FILE="${TMP_DIR}/config.${NAME}"
  echo -n "  ${NAME}: "
  if doctl kubernetes cluster kubeconfig save "$NAME" \
      --expiry-seconds $((7*24*3600)) \
      2>/dev/null; then
    # doctl saves to ~/.kube/config by default — export to file instead
    doctl kubernetes cluster kubeconfig show "$NAME" > "$LOCAL_FILE" 2>/dev/null || true
    echo "saved -> ${LOCAL_FILE}"
  else
    echo "FAILED (cluster not ready?)"
  fi
done

echo ""
echo "==> Copying kubeconfigs to bastion ${BASTION}..."
for i in $(seq 1 "$COUNT"); do
  NAME="${CLUSTER_PREFIX}${i}"
  LOCAL_FILE="${TMP_DIR}/config.${NAME}"
  if [[ -f "$LOCAL_FILE" ]]; then
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
      "$LOCAL_FILE" "${BASTION_USER}@${BASTION}:/tmp/config.${NAME}"
    echo "  /tmp/config.${NAME} -> bastion ok"
  fi
done

echo ""
echo "==> Done. Next step: ./doks-test-clusters.sh"
