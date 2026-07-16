#!/bin/bash
set -e

echo "=== SRE Challenge E2E Test ==="

cleanup() {
  kill $FRONT_MGMT_PID $READER_MGMT_PID $FRONT_API_PID $READER_API_PID 2>/dev/null || true
}

trap cleanup EXIT

check() {
  local description=$1
  local command=$2
  if eval "$command" > /dev/null 2>&1; then
    echo "✅ $description passed"
  else
    echo "❌ $description failed"
    eval "$command"
    exit 1
  fi
}

# port forwards
kubectl port-forward -n demo-front deployment/front 44433:8081 &>/dev/null &
FRONT_MGMT_PID=$!
kubectl port-forward -n demo-reader deployment/reader 44434:8081 &>/dev/null &
READER_MGMT_PID=$!
kubectl port-forward -n demo-front deployment/front 44435:8080 &>/dev/null &
FRONT_API_PID=$!
kubectl port-forward -n demo-reader deployment/reader 44436:8084 &>/dev/null &
READER_API_PID=$!

sleep 3

check "Front healthy" "curl -sf http://localhost:44433/health | grep -q UP"
check "Reader healthy" "curl -sf http://localhost:44434/health | grep -q UP"
check "Topic testCommand exists" \
  "kubectl exec -n kafka statefulset/kafka -- \
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --list | grep -q testCommand"
check "Command sent" \
  "curl -sf -X POST http://localhost:44435/api/v1/command \
  -H 'Content-Type: application/json' \
  -d '{\"type\":\"test\",\"payload\":\"e2e-test\"}'"

sleep 5

RESULT=$(curl -sf http://localhost:44436/api/v1/testEntity)
if ! echo "$RESULT" | grep -q "message"; then
  echo "❌ Data not found in Reader"
  echo "$RESULT"
  exit 1
fi

echo ""
echo "=== All tests passed ==="