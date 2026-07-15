#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HELM_DIR="$PROJECT_DIR/helm"

: ${DB_USERNAME:?DB_USERNAME is required. Export it before running.}
: ${DB_PASSWORD:?DB_PASSWORD is required. Export it before running.}

echo "Linting Helm charts"
helm lint "$HELM_DIR"/*
echo "All charts passed linting"
echo ""

echo "=== SRE Challenge deployment ==="

ORDER=(
  "postgres:postgres"
  "kafka:kafka"
  "back:demo-back"
  "front:demo-front"
  "reader:demo-reader"
)

for entry in "${ORDER[@]}"; do
  chart="${entry%%:*}"
  ns="${entry##*:}"
  echo "Deploying $chart → namespace: $ns"

  if [ "$chart" = "postgres" ]; then
    helm upgrade --install "$chart" "$HELM_DIR/$chart" \
      --namespace "$ns" \
      --create-namespace \
      --set postgres.auth.username="$DB_USERNAME" \
      --set postgres.auth.password="$DB_PASSWORD"
  else
    helm upgrade --install "$chart" "$HELM_DIR/$chart" \
      --namespace "$ns" \
      --create-namespace \
      --set database.username="$DB_USERNAME" \
      --set database.password="$DB_PASSWORD"
  fi

  echo "✅ $chart deployed"
  echo ""
done

echo "Check status:"
echo "  kubectl get pods -A"
echo "Cleanup:"
echo "  ./scripts/teardown.sh"