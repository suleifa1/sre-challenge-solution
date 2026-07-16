#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HELM_DIR="$PROJECT_DIR/helm"

cleanup() {
  rm -f /tmp/front.crt /tmp/front.key /tmp/reader.crt /tmp/reader.key
}

trap cleanup EXIT

: ${DB_USERNAME:?DB_USERNAME is required. Export it before running.}
: ${DB_PASSWORD:?DB_PASSWORD is required. Export it before running.}

echo "=== Linting Helm charts ==="
helm lint "$HELM_DIR"/*
echo "✅ All charts passed linting"
echo ""

echo "=== Generating TLS certificates ==="
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/front.key -out /tmp/front.crt \
  -subj "/CN=front.local/O=sre-challenge" 2>/dev/null
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/reader.key -out /tmp/reader.crt \
  -subj "/CN=reader.local/O=sre-challenge" 2>/dev/null
echo "✅ TLS certificates generated"
echo ""

echo "=== SRE Challenge deployment ==="

echo "Deploying postgres..."
helm upgrade --install postgres "$HELM_DIR/postgres" \
  --namespace postgres --create-namespace \
  --set postgres.auth.username="$DB_USERNAME" \
  --set postgres.auth.password="$DB_PASSWORD"

echo "Deploying kafka..."
helm upgrade --install kafka "$HELM_DIR/kafka" \
  --namespace kafka --create-namespace

echo "Deploying back..."
helm upgrade --install back "$HELM_DIR/back" \
  --namespace demo-back --create-namespace \
  --set database.username="$DB_USERNAME" \
  --set database.password="$DB_PASSWORD"

echo "Deploying front..."
helm upgrade --install front "$HELM_DIR/front" \
  --namespace demo-front --create-namespace \
  --set-file ingress.tls.cert=/tmp/front.crt \
  --set-file ingress.tls.key=/tmp/front.key

echo "Deploying reader..."
helm upgrade --install reader "$HELM_DIR/reader" \
  --namespace demo-reader --create-namespace \
  --set database.username="$DB_USERNAME" \
  --set database.password="$DB_PASSWORD" \
  --set-file ingress.tls.cert=/tmp/reader.crt \
  --set-file ingress.tls.key=/tmp/reader.key

echo ""
echo "✅ All deployed"
echo "Check status: kubectl get pods -A"
echo "Cleanup: ./scripts/teardown.sh"