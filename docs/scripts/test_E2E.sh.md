# test_E2E.sh - End-to-End Testing

## Description

Runs automated end-to-end tests verifying the full data pipeline:
`Front → Kafka → Back → PostgreSQL → Reader`

Uses temporary port-forwards that are automatically cleaned up on exit via `trap`.

## Prerequisites

- All components deployed (`./scripts/deploy-helm.sh`)
- kubectl configured
- curl installed

## Usage

```bash
./scripts/test_E2E.sh
```

## Test Scenarios

| Step | Check | Expected |
| --- | --- | --- |
| 1 | Front management `/health` | `UP` |
| 2 | Reader management `/health` | `UP` |
| 3 | Kafka topic `testCommand` exists | topic listed |
| 4 | POST command via Front API | 200 OK |
| 5 | Data appears in Reader API | `message` field present |

## Port Forwards

The script temporarily opens four port-forwards:

| Local port | Target | Purpose |
| --- | --- | --- |
| 44433 | Front :8081 | Health check |
| 44434 | Reader :8081 | Health check |
| 44435 | Front :8080 | API calls |
| 44436 | Reader :8084 | API calls |

All port-forwards are terminated automatically on script exit.

## Exit Codes

- `0` — all tests passed
- `1` — at least one test failed (error output shown)

## Persistence Verification

To verify data survives Kafka and PostgreSQL restarts:

```bash
kubectl rollout restart statefulset/kafka -n kafka
kubectl rollout restart statefulset/postgresql -n postgres
kubectl rollout status statefulset/kafka -n kafka --timeout=120s
kubectl rollout status statefulset/postgresql -n postgres --timeout=120s

./scripts/test_E2E.sh
```

## Debugging

```bash
# Pod status
kubectl get pods -A

# Back logs
kubectl logs -n demo-back deployment/back

# Kafka topic details
kubectl exec -n kafka statefulset/kafka -- \
  /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe --topic testCommand

# NetworkPolicy status
kubectl get networkpolicy -A
```