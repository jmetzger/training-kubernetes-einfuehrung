#!/bin/bash
# Creates 16 Checkmk (Cloud Edition) Droplets for training (tln1..tln16)
# Region: fra1, Size: s-4vcpu-8gb, Image: ubuntu-24-04-x64
# DNS A-Records in do.t3isp.de are created automatically by cloud-init

set -euo pipefail

REGION="fra1"
SIZE="s-4vcpu-8gb"
IMAGE="ubuntu-24-04-x64"
PREFIX="tln"
COUNT=16
CMK_PASSWORD="11dortmund22"
TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="${TEMPLATE_DIR}/cloud-init-checkmk.sh.template"

if [[ -z "${DO_TOKEN:-}" ]]; then
  echo "ERROR: DO_TOKEN nicht gesetzt."
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template nicht gefunden: $TEMPLATE"
  exit 1
fi

# Substitute placeholders and store in temp file
TMPFILE="$HOME/cloud-init-checkmk-current.sh"
trap 'rm -f "$TMPFILE"' EXIT
sed \
  -e "s|__DO_TOKEN__|${DO_TOKEN}|g" \
  -e "s|__CMK_PASSWORD__|${CMK_PASSWORD}|g" \
  "$TEMPLATE" > "$TMPFILE"

echo "==> Erstelle $COUNT Checkmk-Droplets (${PREFIX}1..${PREFIX}${COUNT})"
echo "==> Region: $REGION  Size: $SIZE  Image: $IMAGE"
echo ""

for i in $(seq 1 "$COUNT"); do
  NAME="${PREFIX}${i}"
  echo -n "  Erstelle $NAME ... "
  doctl compute droplet create "$NAME" \
    --region "$REGION" \
    --size "$SIZE" \
    --image "$IMAGE" \
    --user-data-file "$TMPFILE" \
    2>&1 | tail -1 || true
  echo "submitted"
done

echo ""
echo "==> Alle $COUNT Droplets submitted (cloud-init läuft im Hintergrund ~10 Min)."
echo ""
echo "==> Status prüfen:"
echo "    doctl compute droplet list --format Name,PublicIPv4,Status | grep tln"
echo "    doctl compute domain records list do.t3isp.de | grep tln"
echo ""
echo "==> SSH testen (nach ~2 Min):"
echo "    ssh 11trainingdo@tln1.do.t3isp.de  (Passwort: 11dortmund22)"
echo ""
echo "==> Checkmk URLs (nach ~10 Min):"
for i in $(seq 1 "$COUNT"); do
  echo "    https://tln${i}.do.t3isp.de/cmk/"
done
