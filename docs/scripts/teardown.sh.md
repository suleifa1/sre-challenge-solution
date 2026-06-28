# teardown.sh - Resource Cleanup

## Description

The script completely removes all deployed Helm charts and created namespaces, restoring the cluster to its initial state.

## Prerequisites

- Kubernetes cluster running and accessible
- kubectl configured
- Helm 3.x installed

## Usage

```bash
./scripts/teardown.sh
```

## Execution Process

The script performs the following actions in reverse deployment order:

1. **Remove Reader**: deletes Helm release `reader` from namespace `demo-reader`
2. **Remove Front**: deletes Helm release `front` from namespace `demo-front`
3. **Remove Back**: deletes Helm release `back` from namespace `demo-back`
4. **Remove Kafka**: deletes Helm release `kafka` from namespace `kafka`
5. **Remove PostgreSQL**: deletes Helm release `postgres` from namespace `postgres`
6. **Remove namespaces**: deletes created namespaces (if included in script)

## What Gets Removed

- All Deployments
- All Services
- All ConfigMaps
- All Secrets
- All Ingresses
- All Jobs (Helm hooks)
- All PVCs (if created)
- All namespaces

## Data After Cleanup

**Warning**: cleanup will result in loss of all data in PostgreSQL, data stored in Kafka memory, and deployment information.

To preserve critical data before cleanup:
```bash
# PostgreSQL backup
kubectl exec -n postgres <pod-name> -- pg_dump -U postgres > backup.sql

# Export other data
kubectl logs -n <namespace> <pod-name> > logs.txt
```

## Verification of Cleanup

After script execution:

```bash
# Verify no pods running
kubectl get pods -A

# Verify no namespaces
kubectl get ns

# Verify no Helm releases (should be empty)
helm list -A
```

## Partial Cleanup

To remove only individual component:

```bash
# Remove only Reader
helm uninstall reader -n demo-reader

# Remove only Back
helm uninstall back -n demo-back

# Remove namespace
kubectl delete ns demo-reader
```

## Re-deployment

After running `teardown.sh`, re-deployment is possible. Docker images remain in Minikube Docker, so `build.sh` is not required:

```bash
./scripts/deploy-helm.sh
```

If image rebuild is needed:
```bash
./scripts/build.sh
./scripts/deploy-helm.sh
```

## Possible Errors

| Error | Solution |
|-------|----------|
| Release not found | Helm release was not deployed or already deleted |
| Namespace terminating | Wait for cleanup completion or use `kubectl delete ns <name> --force --grace-period=0` |
| Permission denied | Check cluster access rights |
