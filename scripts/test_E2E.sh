#!/bin/bash
set -e

echo "=== SRE Challenge E2E Test ==="

# Port forward management ports (health checks)
kubectl port-forward -n demo-front deployment/front 44433:8081 &
FRONT_MGMT_PID=$!
kubectl port-forward -n demo-reader deployment/reader 44434:8081 &
READER_MGMT_PID=$!

# Port forward api ports
kubectl port-forward -n demo-front deployment/front 44435:8080 &
FRONT_API_PID=$!
kubectl port-forward -n demo-reader deployment/reader 44436:8084 &
READER_API_PID=$!

sleep 3

echo ""
echo "[1/6] Checking Front health..."
curl -sf http://localhost:44433/health | grep -q "UP" && echo "✅ Front healthy" || echo "❌ Front unhealthy"

echo ""
echo "[2/6] Checking Reader health..."
curl -sf http://localhost:44434/health | grep -q "UP" && echo "✅ Reader healthy" || echo "❌ Reader unhealthy"

echo ""
echo "[3/6] Checking Kafka topic..."
kubectl exec -n kafka deployment/kafka -- \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list | grep -q "testCommand" && echo "✅ Topic testCommand exists" || echo "❌ Topic not found"

echo ""
echo "[4/6] Checking Kafka topic details..."
kubectl exec -n kafka deployment/kafka -- \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic testCommand

echo ""
echo "[5/6] Sending command via Front API..."
curl -sf -X POST http://localhost:44435/api/v1/command \
  -H "Content-Type: application/json" \
  -d '{"type":"test","payload":"e2e-test"}' && echo "✅ Command sent"

sleep 3

echo ""
echo "[6/6] Reading data from Reader API..."
RESULT=$(curl -sf http://localhost:44436/api/v1/testEntity)
echo "$RESULT" | grep -q "message" && echo "✅ Data found in Reader" || echo "❌ No data in Reader"
echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"

echo ""
echo "=== Test complete ==="

# Cleanup
kill $FRONT_MGMT_PID $READER_MGMT_PID $FRONT_API_PID $READER_API_PID 2>/dev/null || true