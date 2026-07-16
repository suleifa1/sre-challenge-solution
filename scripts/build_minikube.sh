#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)/sre-challenge"

cd "$PROJECT_ROOT"

echo "=== Switching to minikube docker daemon ==="
eval $(minikube docker-env)

echo "=== Building Docker images ==="
for app in front back reader; do
  echo "--- Building ${app} ---"
  docker build \
    -f app/${app}/src/main/docker/Dockerfile \
    -t "${app}:0.1.0" \
    .
  echo " ${app}:0.1.0 ready"
done

echo ""
echo "=== Done ==="
docker images | grep -E "REPOSITORY|front|back|reader"