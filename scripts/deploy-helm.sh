#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HELM_DIR="$PROJECT_DIR/helm"

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
  helm upgrade --install "$chart" "$HELM_DIR/$chart" \
    --namespace "$ns" \
    --create-namespace
  echo "$chart deployed"
  echo ""
done

echo "Check status:"
echo "  kubectl get pods -A"
echo "Cleanup:"
echo "  helm uninstall reader -n demo-reader && \\"
echo "  helm uninstall front -n demo-front && \\"
echo "  helm uninstall back -n demo-back && \\"
echo "  helm uninstall kafka -n kafka && \\"
echo "  helm uninstall postgres -n postgres"