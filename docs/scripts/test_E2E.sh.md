# test_E2E.sh - End-to-End Testing

## Description

The script performs comprehensive testing of the deployed system functionality after running `deploy-helm.sh`. It checks the availability of all components, correctness of interactions between services, and data processing integrity.

## Prerequisites

- All components deployed (see deploy-helm.sh)
- kubectl installed and configured
- curl installed in the system
- Port-forwards established for service access (or hosts configured)

## Usage

```bash
./scripts/test_E2E.sh
```

## Test Scenarios

### 1. Service Availability Check

**Front:**
- HTTP 200 check on `/swagger-ui.html`
- Management endpoint check `/health`

**Back:**
- HTTP 200 check on `/swagger-ui.html`
- Management endpoint check `/health`

**Reader:**
- HTTP 200 check on `/swagger-ui.html`
- Management endpoint check `/health`

### 2. Kubernetes Resources Check

```bash
# Status of all pods
kubectl get pods -A

# Status of services
kubectl get svc -A

# Ingress check
kubectl get ingress -A
```

### 3. Functional Testing

**Send command through Front:**
```bash
curl -X POST http://127.0.0.1:8080/api/v1/command \
  -H "Content-Type: application/json" \
  -d '{
    "message": "test message",
    "loadFront": 100,
    "loadBack": 100
  }'
```

**Verify data persistence in Reader:**
```bash
curl http://127.0.0.1:8084/api/v1/testEntity
```

**Verify Kafka processing:**
- Check `testCommand` topic presence
- Verify message processing by Back
- Verify database writes

## Expected Results

| Check | Expected Result |
|-------|-----------------|
| HTTP 200 on Front/Back/Reader | Services are accessible |
| Health endpoints return UP | Applications are healthy |
| POST to Front is accepted | API is functional |
| Data in Reader matches sent data | Data pipeline is working |
| Kafka topic exists | Messages are being processed |

## Debugging on Errors

### Service Unavailable

```bash
# Check port-forward
kubectl port-forward -n demo-front svc/front 8080:8080

# Check pod
kubectl describe pod -n demo-front <pod-name>

# Check network policies (if present)
kubectl get networkpolicies -A
```

### Data Not Reaching Reader

```bash
# Check Back logs
kubectl logs -n demo-back -l app=back | grep -i error

# Check Kafka
kubectl exec -n kafka <pod-name> -- /opt/kafka/bin/kafka-topics.sh \
  --list --bootstrap-server localhost:9092

# Check database
kubectl exec -n postgres <pod-name> -- psql -U postgres -l
```

### Health Endpoints Return Errors

```bash
# Get full health information
curl http://127.0.0.1:8081/health -v

# Check dependencies
curl http://127.0.0.1:8081/health/liveness
curl http://127.0.0.1:8081/health/readiness
```

## Test Results

After successful execution of all tests, the system is considered ready for use.
